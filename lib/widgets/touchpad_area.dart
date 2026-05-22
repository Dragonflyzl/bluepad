import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../utils/l10n_utils.dart';

/// 触控板区域组件 - v4优化版
/// 核心策略：
/// - 鼠标移动：事件驱动 + 即时发送，使用 event.delta（亚像素精度）
/// - 双指滚动：使用 event.delta 逐指计算（每根手指各自追踪自己的位移），克服 avgPos 量化噪声
/// - 双指过渡保护：双指→单指时短暂屏蔽鼠标移动，防止残余位移引起鼠标漂移
/// - 基于位移大小的加速度增益（不依赖时间，事件频率波动不影响增益稳定性）
/// - 极小死区 + 累加器截断
class TouchPadArea extends StatefulWidget {
  final double sensitivity;
  final double scrollSensitivity;
  final bool tapToClick;
  final bool naturalScroll;
  final bool inertia;
  final Function(double dx, double dy, int buttonMask) onMouseMove;
  final Function(MouseButton button) onMouseClick;
  final Function(double vertical, double horizontal) onScroll;
  final VoidCallback? onThreeFingerTap;
  final Function(SwipeDirection direction)? onThreeFingerSwipe;
  final VoidCallback? onZoomStart;
  final Function(double delta)? onZoomUpdate;
  final VoidCallback? onZoomEnd;

  const TouchPadArea({
    super.key,
    this.sensitivity = 1.0,
    this.scrollSensitivity = 1.0,
    this.tapToClick = true,
    this.naturalScroll = true,
    this.inertia = true,
    required this.onMouseMove,
    required this.onMouseClick,
    required this.onScroll,
    this.onThreeFingerTap,
    this.onThreeFingerSwipe,
    this.onZoomStart,
    this.onZoomUpdate,
    this.onZoomEnd,
  });

  @override
  State<TouchPadArea> createState() => _TouchPadAreaState();
}

enum SwipeDirection { up, down, left, right }

class _TouchPadAreaState extends State<TouchPadArea> {
  // ==================== 状态变量 ====================
  final ValueNotifier<Offset?> _feedbackNotifier = ValueNotifier<Offset?>(null);
  final Map<int, Offset> _pointers = {};
  // 每根手指独立追踪上一帧位置（用于逐指 delta 计算）
  final Map<int, Offset> _lastFingerPos = {};

  Offset _lastAvgPos = Offset.zero;
  double _totalDist = 0;
  DateTime? _downTime;
  int _maxPointers = 0;

  // 高精度累加器
  double _accX = 0;
  double _accY = 0;
  double _accScrollV = 0;
  double _accScrollH = 0;

  DateTime? _lastUpTime;
  bool _lastGestureWasTap = false;
  bool _isDraggingMode = false;

  // 手势模式
  int _gestureMode = 0;
  Offset _threeFingerTotalDelta = Offset.zero;

  double _initialPinchDistance = -1.0;
  double _lastPinchDistance = -1.0;

  VelocityTracker _velocityTracker =
      VelocityTracker.withKind(PointerDeviceKind.touch);
  Timer? _inertiaTimer;

  // 双指→单指过渡保护：过渡后忽略前 N 帧鼠标移动，防止残余位移导致鼠标漂移
  int _transitionHoldFrames = 0;
  static const int _kTransitionHoldMax = 3;

  // ==================== 常量 ====================

  static const double _kDeadZone = 0.1;
  static const double _kAccelDistanceThreshold = 1.5;
  static const double _kAccelCurve = 0.45;
  static const double _kMaxGain = 2.5;
  static const double _kBaseSensitivity = 1.0;

  @override
  void dispose() {
    _inertiaTimer?.cancel();
    _feedbackNotifier.dispose();
    super.dispose();
  }

  // ==================== 位移型加速度增益 ====================

  double _distanceAccelGain(double distance) {
    if (distance < _kAccelDistanceThreshold) return 1.0;
    final ratio = (distance - _kAccelDistanceThreshold) / _kAccelDistanceThreshold;
    final cappedRatio = min(ratio, 5.0);
    final gain = 1.0 + pow(cappedRatio, _kAccelCurve).toDouble();
    return min(gain, _kMaxGain);
  }

  // ==================== 发送鼠标移动 ====================

  void _sendMouseMoveImmediate(double rawDx, double rawDy, {int buttonMask = 0}) {
    final distance = sqrt(rawDx * rawDx + rawDy * rawDy);
    final gain = _distanceAccelGain(distance);

    double dx = rawDx * widget.sensitivity * _kBaseSensitivity * gain;
    double dy = rawDy * widget.sensitivity * _kBaseSensitivity * gain;

    if (dx.abs() < _kDeadZone && dy.abs() < _kDeadZone) return;

    _accX += dx;
    _accY += dy;
    final sendX = _accX.truncate();
    final sendY = _accY.truncate();

    if (sendX != 0 || sendY != 0) {
      widget.onMouseMove(sendX.toDouble(), sendY.toDouble(), buttonMask);
      _accX -= sendX;
      _accY -= sendY;
    }
  }

  // ==================== 发送双指滚动 - 还原直接映射 ====================

  void _sendScrollImmediate(double rawV, double rawH) {
    // 滚动不同鼠标：每个单位 = 滚轮"一格"，不应被敏感度缩放
    // 直接累积原始值，truncate 发送，确保极慢速移动也能逐格响应
    _accScrollV += rawV;
    _accScrollH += rawH;
    final sendV = _accScrollV.truncate();
    final sendH = _accScrollH.truncate();

    if (sendV != 0 || sendH != 0) {
      widget.onScroll(sendV.toDouble(), sendH.toDouble());
      _accScrollV -= sendV;
      _accScrollH -= sendH;
    }
  }

  /// 计算双指平均 delta（逐指追踪，避免 avgPos 重算的量化噪声）
  Offset _twoFingerScrollDelta() {
    if (_pointers.length < 2) return Offset.zero;

    // 对于每根手指，用当前 position - 该手指的上帧 position 计算 delta
    final keys = _pointers.keys.toList();
    Offset sum = Offset.zero;
    int count = 0;

    for (final key in keys) {
      final currentPos = _pointers[key];
      final lastPos = _lastFingerPos[key];
      if (currentPos != null && lastPos != null) {
        sum += currentPos - lastPos;
        count++;
      }
    }

    if (count == 0) return Offset.zero;
    return sum / count.toDouble();
  }

  // ==================== 手势处理 ====================

  void _handlePointerDown(PointerDownEvent event) {
    _inertiaTimer?.cancel();
    _pointers[event.pointer] = event.localPosition;
    _lastFingerPos[event.pointer] = event.localPosition;

    _lastAvgPos = _calculateAvgPos();
    _feedbackNotifier.value = _lastAvgPos;

    if (_pointers.length == 1) {
      _downTime = DateTime.now();
      _totalDist = 0;
      _maxPointers = 1;

      _accX = 0;
      _accY = 0;
      _accScrollV = 0;
      _accScrollH = 0;
      _gestureMode = 0;
      _threeFingerTotalDelta = Offset.zero;
      _initialPinchDistance = -1.0;
      _lastPinchDistance = -1.0;
      _transitionHoldFrames = 0;

      final now = DateTime.now();
      _isDraggingMode = (_lastUpTime != null &&
          now.difference(_lastUpTime!).inMilliseconds < 200 &&
          _lastGestureWasTap);
    } else {
      if (_pointers.length > _maxPointers) _maxPointers = _pointers.length;

      if (_pointers.length == 2) {
        _accScrollV = 0;
        _accScrollH = 0;
        _initialPinchDistance = _currentPinchDistance();
        _lastPinchDistance = _initialPinchDistance;

        if (_gestureMode != 1) {
          _gestureMode = 0;
        }
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;

    _velocityTracker.addPosition(event.timeStamp, event.position);

    // *** v4 fix: 先记录上一帧位置到 _lastFingerPos，再更新本帧位置到 _pointers ***
    // 如果先更新 _lastFingerPos，_twoFingerScrollDelta 读到的 lastPos == currentPos，delta 恒为0
    _lastFingerPos[event.pointer] = _pointers[event.pointer] ?? event.localPosition;
    _pointers[event.pointer] = event.localPosition;

    final avgPos = _calculateAvgPos();
    final delta = avgPos - _lastAvgPos;
    _totalDist += delta.distance;
    _feedbackNotifier.value = avgPos;

    if (_pointers.length == 1) {
      // === 单指模式 ===
      if (_isDraggingMode && _gestureMode == 0 && delta.distance > 2) {
        _gestureMode = 1;
      }

      if (_gestureMode == 0 || _gestureMode == 1) {
        // *** 过渡保护：双指→单指后，忽略前几帧的残余位移 ***
        if (_transitionHoldFrames > 0) {
          _transitionHoldFrames--;
          _lastAvgPos = avgPos;
          return;
        }
        _sendMouseMoveImmediate(
          event.delta.dx,
          event.delta.dy,
          buttonMask: _gestureMode == 1 ? 0x01 : 0,
        );
      }
    } else if (_pointers.length == 2) {
      // === 双指模式 ===
      final currentPinch = _currentPinchDistance();

      if (_initialPinchDistance < 0) {
        _initialPinchDistance = currentPinch;
        _lastPinchDistance = currentPinch;
      }

      if (_gestureMode == 0) {
        final pinchDelta = (currentPinch - _initialPinchDistance).abs();
        final scrollDelta = delta.distance;

        if (pinchDelta > 12.0) {
          _gestureMode = 3;
          _lastPinchDistance = currentPinch;
          _lastAvgPos = avgPos;
          widget.onZoomStart?.call();
        } else if (scrollDelta > 1.0) {
          _gestureMode = 2;
          _accScrollV = 0;
          _accScrollH = 0;
          _lastAvgPos = avgPos;
        }
      }

      if (_gestureMode == 2) {
        // *** v4: 使用逐指追踪的 delta，而非 avgPos 差值 ***
        // 每根手指独立跟踪位移，避免 avgPos 重算的量化噪声
        final fingerDelta = _twoFingerScrollDelta();

        // *** v4.4: 滚动缩放 = 1/3，让滚动速度适中 ***
        // 直接 1:1 太快（双指在手机屏上滑 1px = 滚轮 1 格，像素密度太高）
        // 约3像素 = 1格，配合 scrollSensitivity 让用户可以调节
        final scrollFactor = widget.naturalScroll ? -1.0 : 1.0;
        final scrollScale = 1.0 / (7.0 * widget.scrollSensitivity);
        final rawV = fingerDelta.dy * scrollFactor * scrollScale;
        final rawH = fingerDelta.dx * -scrollFactor * scrollScale;

        _sendScrollImmediate(rawV, rawH);
      } else if (_gestureMode == 3) {
        final scale = currentPinch / _lastPinchDistance;
        if ((scale - 1.0).abs() > 0.005) {
          widget.onZoomUpdate?.call(scale - 1.0);
          _lastPinchDistance = currentPinch;
        }
      }

      // 双指模式下也更新 _lastAvgPos，为过渡到单指做准备
      _lastAvgPos = avgPos;
    } else if (_pointers.length == 3) {
      if (_gestureMode != 4) {
        _gestureMode = 4;
        _threeFingerTotalDelta = Offset.zero;
      }
      if (_gestureMode == 4) {
        _threeFingerTotalDelta += delta;
      }
      _lastAvgPos = avgPos;
    } else {
      _lastAvgPos = avgPos;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final upTime = DateTime.now();
    final pointer = event.pointer;

    // 清除该手指的状态
    _pointers.remove(pointer);
    _lastFingerPos.remove(pointer);

    if (_pointers.isNotEmpty) {
      _lastAvgPos = _calculateAvgPos();
      _feedbackNotifier.value = _lastAvgPos;

      if (_gestureMode == 4 && _pointers.length == 2) {
        _gestureMode = 2;
        _accScrollV = 0;
        _accScrollH = 0;
        _initialPinchDistance = _currentPinchDistance();
        _lastPinchDistance = _initialPinchDistance;
      } else if (_gestureMode == 4 && _pointers.length == 1) {
        // 三指→单指：激活过渡保护
        _gestureMode = 0;
        _accX = 0;
        _accY = 0;
        _transitionHoldFrames = _kTransitionHoldMax;
      } else if (_pointers.length == 1 && _gestureMode == 3) {
        widget.onZoomEnd?.call();
        _gestureMode = 0;
        _initialPinchDistance = -1.0;
        _lastPinchDistance = -1.0;
        _transitionHoldFrames = _kTransitionHoldMax;
      } else if (_pointers.length == 1 && _gestureMode == 2) {
        // *** v4: 双指→单指过渡：激活过渡保护 ***
        // 此时还剩一指在屏幕上，立即切为 mode 0 会导致下一帧 move 把残余位移送去鼠标
        // 过渡保护忽略前 N 帧的 event.delta，等手指稳定后再响应鼠标移动
        _accScrollV = 0;
        _accScrollH = 0;
        _gestureMode = 0;
        _transitionHoldFrames = _kTransitionHoldMax;
      }

      return;
    }

    // ====== 所有手指离开 ======
    _feedbackNotifier.value = null;

    if (_gestureMode == 0 || _gestureMode == 1) {
      _accX = 0;
      _accY = 0;
    } else if (_gestureMode == 2) {
      _accScrollV = 0;
      _accScrollH = 0;
    }

    if (_gestureMode == 1) {
      widget.onMouseMove(0, 0, 0);
    } else if (_gestureMode == 3) {
      widget.onZoomEnd?.call();
    } else if (_gestureMode == 4) {
      final dx = _threeFingerTotalDelta.dx;
      final dy = _threeFingerTotalDelta.dy;
      if (dx.abs() > 50 || dy.abs() > 50) {
        if (dx.abs() > dy.abs()) {
          if (dx > 0) {
            widget.onThreeFingerSwipe?.call(SwipeDirection.right);
          } else {
            widget.onThreeFingerSwipe?.call(SwipeDirection.left);
          }
        } else {
          if (dy > 0) {
            widget.onThreeFingerSwipe?.call(SwipeDirection.down);
          } else {
            widget.onThreeFingerSwipe?.call(SwipeDirection.up);
          }
        }
      } else if (_totalDist < 20) {
        widget.onThreeFingerTap?.call();
      }
    } else if (_gestureMode == 2 && widget.inertia) {
      _startInertia(isScroll: true);
    } else if (_gestureMode == 0 && widget.inertia) {
      _startInertia(isScroll: false);
    }

    _initialPinchDistance = -1.0;
    _lastPinchDistance = -1.0;

    final duration = upTime.difference(_downTime ?? upTime).inMilliseconds;
    final isTap = _totalDist < 15 && duration < 300 && (_gestureMode == 0 || _isDraggingMode);

    if (isTap) {
      if (widget.tapToClick && _maxPointers == 1) {
        if (_isDraggingMode) {
          widget.onMouseClick(MouseButton.left);
        } else {
          widget.onMouseClick(MouseButton.left);
        }
      } else if (_maxPointers == 2) {
        widget.onMouseClick(MouseButton.right);
      }
    }

    _lastUpTime = upTime;
    _lastGestureWasTap = isTap;
    _maxPointers = 0;
    _gestureMode = 0;
    _isDraggingMode = false;
    _transitionHoldFrames = 0;
    _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final pointer = event.pointer;
    _pointers.remove(pointer);
    _lastFingerPos.remove(pointer);

    if (_pointers.isNotEmpty) {
      _lastAvgPos = _calculateAvgPos();
      _feedbackNotifier.value = _lastAvgPos;
      return;
    }

    _feedbackNotifier.value = null;

    if (_gestureMode == 1) {
      widget.onMouseMove(0, 0, 0);
    } else if (_gestureMode == 3) {
      widget.onZoomEnd?.call();
    }

    _gestureMode = 0;
    _isDraggingMode = false;
    _maxPointers = 0;
    _accX = 0;
    _accY = 0;
    _accScrollV = 0;
    _accScrollH = 0;
    _transitionHoldFrames = 0;
    _initialPinchDistance = -1.0;
    _lastPinchDistance = -1.0;
    _inertiaTimer?.cancel();
    _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
  }

  // ==================== 惯性 ====================

  void _startInertia({required bool isScroll}) {
    final velocity = _velocityTracker.getVelocity().pixelsPerSecond;
    if (velocity.distance < 150) return;

    double vx = velocity.dx;
    double vy = velocity.dy;

    _inertiaTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
      vx *= 0.92;
      vy *= 0.92;
      if (vx.abs() < 1 && vy.abs() < 1) {
        timer.cancel();
        return;
      }

      if (isScroll) {
        final scrollFactor = widget.naturalScroll ? -1.0 : 1.0;
        final scrollDamping = 5.0 / widget.scrollSensitivity;
        widget.onScroll(vy * 0.016 * scrollFactor / scrollDamping,
            vx * 0.016 * scrollFactor / scrollDamping);
      } else {
        widget.onMouseMove(
            vx * 0.016 * widget.sensitivity, vy * 0.016 * widget.sensitivity, 0);
      }
    });
  }

  // ==================== 辅助方法 ====================

  double _currentPinchDistance() {
    if (_pointers.length < 2) return 0.0;
    final keys = _pointers.keys.toList();
    final p1 = _pointers[keys[0]]!;
    final p2 = _pointers[keys[1]]!;
    return (p1 - p2).distance;
  }

  Offset _calculateAvgPos() {
    if (_pointers.isEmpty) return Offset.zero;
    Offset sum = Offset.zero;
    for (var pos in _pointers.values) {
      sum += pos;
    }
    return sum / _pointers.length.toDouble();
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant =
        isDark ? DarkColors.text2 : LightColors.text2;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;

    final List<Color> bgColors = isDark
        ? [const Color(0xFF111318), const Color(0xFF0A0C10)]
        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)];

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: RepaintBoundary(
          child: ValueListenableBuilder<Offset?>(
            valueListenable: _feedbackNotifier,
            builder: (context, pos, _) {
              return CustomPaint(
                painter: _TouchpadPainter(
                  feedbackPos: pos,
                  isDark: isDark,
                  accentColor: accentColor,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: onSurfaceVariant.withValues(alpha: 0.2),
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.s('touch_hint'),
                        style: TextStyle(
                          color: onSurfaceVariant.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TouchpadPainter extends CustomPainter {
  final Offset? feedbackPos;
  final bool isDark;
  final Color accentColor;

  _TouchpadPainter(
      {this.feedbackPos, required this.isDark, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF2A2F3A) : const Color(0xFF94A3B8))
          .withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    const gridSize = 90.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (feedbackPos != null) {
      canvas.drawCircle(
        feedbackPos!,
        80,
        Paint()..color = accentColor.withValues(alpha: 0.1),
      );
      canvas.drawCircle(
        feedbackPos!,
        40,
        Paint()..color = accentColor.withValues(alpha: 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TouchpadPainter oldDelegate) =>
      oldDelegate.feedbackPos != feedbackPos ||
      oldDelegate.isDark != isDark;
}
