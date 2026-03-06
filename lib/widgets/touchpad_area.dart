import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../utils/l10n_utils.dart';

/// 触控板区域组件
/// 对应 Android: TouchPadArea.kt
/// 支持单指移动、点击、双指滚动、缩放、三指轻点、轻扫以及惯性滚动
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
  final ValueNotifier<Offset?> _feedbackNotifier = ValueNotifier<Offset?>(null);
  final Map<int, Offset> _pointers = {};

  Offset _lastAvgPos = Offset.zero;
  double _totalDist = 0;
  DateTime? _downTime;
  int _maxPointers = 0;

  // 累加器，用于处理高分屏微调
  double _accX = 0;
  double _accY = 0;
  double _accScrollV = 0;
  double _accScrollH = 0;

  DateTime? _lastUpTime;
  bool _lastGestureWasTap = false;
  bool _isDraggingMode = false;

  // 模式：0=None, 1=Drag, 2=Scroll, 3=Zoom, 4=3-Finger
  int _gestureMode = 0;
  int _previousGestureMode = 0;
  Offset _threeFingerTotalDelta = Offset.zero;

  // 修复：独立维护双指初始距离，与 gestureMode 无关
  double _initialPinchDistance = -1.0; // -1 表示未初始化
  double _lastPinchDistance = -1.0;

  VelocityTracker _velocityTracker =
      VelocityTracker.withKind(PointerDeviceKind.touch);
  Timer? _inertiaTimer;

  void _handlePointerDown(PointerDownEvent event) {
    _inertiaTimer?.cancel();
    _pointers[event.pointer] = event.localPosition;

    _lastAvgPos = _calculateAvgPos();
    _feedbackNotifier.value = _lastAvgPos;

    if (_pointers.length == 1) {
      _downTime = DateTime.now();
      _totalDist = 0;
      _maxPointers = 1;
      _accX = 0;
      _accY = 0;
      _gestureMode = 0;
      _threeFingerTotalDelta = Offset.zero;

      // 重置缩放状态
      _initialPinchDistance = -1.0;
      _lastPinchDistance = -1.0;

      final now = DateTime.now();
      _isDraggingMode = (_lastUpTime != null &&
          now.difference(_lastUpTime!).inMilliseconds < 300 &&
          _lastGestureWasTap);

      if (_isDraggingMode) _gestureMode = 1;
    } else {
      if (_pointers.length > _maxPointers) _maxPointers = _pointers.length;

      // 第二根手指落下时，立即初始化双指距离基准
      if (_pointers.length == 2) {
        _initialPinchDistance = _currentPinchDistance();
        _lastPinchDistance = _initialPinchDistance;
        // 重置滚动累加器
        _accScrollV = 0;
        _accScrollH = 0;
        // 重置手势模式，重新判断是滚动还是缩放
        if (_gestureMode != 1) {
          _gestureMode = 0;
        }
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;

    _velocityTracker.addPosition(event.timeStamp, event.position);
    _pointers[event.pointer] = event.localPosition;

    final avgPos = _calculateAvgPos();
    final delta = avgPos - _lastAvgPos;
    _totalDist += delta.distance;
    _feedbackNotifier.value = avgPos;

    if (_pointers.length == 1) {
      if (_gestureMode == 0 || _gestureMode == 1) {
        _accX += delta.dx * widget.sensitivity;
        _accY += delta.dy * widget.sensitivity;

        int sendX = _accX.truncate();
        int sendY = _accY.truncate();

        if (sendX != 0 || sendY != 0) {
          widget.onMouseMove(
              sendX.toDouble(), sendY.toDouble(), _gestureMode == 1 ? 0x01 : 0);
          _accX -= sendX;
          _accY -= sendY;
        }
      }
    } else if (_pointers.length == 2) {
      final currentPinch = _currentPinchDistance();

      // 确保基准距离已初始化（防御性处理）
      if (_initialPinchDistance < 0) {
        _initialPinchDistance = currentPinch;
        _lastPinchDistance = currentPinch;
      }

      if (_gestureMode == 0) {
        // 同时计算两个判据，哪个超过门槛就优先进入对应模式
        final pinchDelta = (currentPinch - _initialPinchDistance).abs();
        final scrollDelta = delta.distance;

        if (pinchDelta > 12.0) {
          // 缩放优先：双指间距变化明显
          _gestureMode = 3;
          _lastPinchDistance = currentPinch;
          widget.onZoomStart?.call();
        } else if (scrollDelta > 1.0) {
          // 滚动：双指平移
          _gestureMode = 2;
          _accScrollV = 0;
          _accScrollH = 0;
        }
      }

      if (_gestureMode == 2) {
        final scrollFactor = widget.naturalScroll ? -1.0 : 1.0;
        final scrollDamping = 20.0 / widget.scrollSensitivity;
        _accScrollV += (delta.dy * scrollFactor) / scrollDamping;
        _accScrollH += (delta.dx * scrollFactor) / scrollDamping;

        int sendV = _accScrollV.truncate();
        int sendH = _accScrollH.truncate();

        if (sendV != 0 || sendH != 0) {
          widget.onScroll(sendV.toDouble(), sendH.toDouble());
          _accScrollV -= sendV;
          _accScrollH -= sendH;
        }
      } else if (_gestureMode == 3) {
        // 修复：用当前距离与上一帧距离计算增量，而非与初始值计算
        final scale = currentPinch / _lastPinchDistance;
        if ((scale - 1.0).abs() > 0.005) {
          widget.onZoomUpdate?.call(scale - 1.0);
          _lastPinchDistance = currentPinch;
        }
      }
    } else if (_pointers.length == 3) {
      if (_gestureMode != 4) {
        _previousGestureMode = _gestureMode;
        _gestureMode = 4;
        _threeFingerTotalDelta = Offset.zero;
      }
      if (_gestureMode == 4) {
        _threeFingerTotalDelta += delta;
      }
    }

    _lastAvgPos = avgPos;
  }

  void _handlePointerUp(PointerUpEvent event) {
    final upTime = DateTime.now();
    _pointers.remove(event.pointer);

    if (_pointers.isNotEmpty) {
      _lastAvgPos = _calculateAvgPos();
      _feedbackNotifier.value = _lastAvgPos;

      // 三指 → 两指：切换到滚动模式
      if (_gestureMode == 4 && _pointers.length == 2) {
        _gestureMode = 2;
        _accScrollV = 0;
        _accScrollH = 0;
        // 重新初始化双指距离基准
        _initialPinchDistance = _currentPinchDistance();
        _lastPinchDistance = _initialPinchDistance;
      } else if (_gestureMode == 4 && _pointers.length == 1) {
        _gestureMode = 0;
      } else if (_pointers.length == 1 && _gestureMode == 3) {
        // 缩放结束，切回普通模式
        widget.onZoomEnd?.call();
        _gestureMode = 0;
        _initialPinchDistance = -1.0;
        _lastPinchDistance = -1.0;
      } else if (_pointers.length == 1 && _gestureMode == 2) {
        // 双指滚动减少到单指，切回普通模式
        _gestureMode = 0;
      }

      return;
    }

    // 所有手指离开
    _feedbackNotifier.value = null;

    if (_gestureMode == 1) {
      widget.onMouseMove(0, 0, 0); // 停止拖拽
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

    // 重置缩放状态
    _initialPinchDistance = -1.0;
    _lastPinchDistance = -1.0;

    final duration =
        upTime.difference(_downTime ?? upTime).inMilliseconds;
    final isTap =
        _totalDist < 15 && duration < 300 && _gestureMode == 0;

    if (isTap) {
      if (widget.tapToClick && _maxPointers == 1) {
        widget.onMouseClick(MouseButton.left);
      } else if (_maxPointers == 2) {
        widget.onMouseClick(MouseButton.right);
      }
    }

    _lastUpTime = upTime;
    _lastGestureWasTap = isTap;
    _maxPointers = 0;
    _gestureMode = 0;
    _isDraggingMode = false;
    _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
  }

  /// 处理触摸取消事件（当系统取消触摸时调用，如多点触控冲突）
  void _handlePointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);

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
    _initialPinchDistance = -1.0;
    _lastPinchDistance = -1.0;
    _inertiaTimer?.cancel();
    _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
  }

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

  /// 计算当前双指间距
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

  @override
  void dispose() {
    _inertiaTimer?.cancel();
    _feedbackNotifier.dispose();
    super.dispose();
  }

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
                        color: onSurfaceVariant.withOpacity(0.2),
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.s('touch_hint'),
                        style: TextStyle(
                          color: onSurfaceVariant.withOpacity(0.3),
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
          .withOpacity(0.1)
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
        Paint()..color = accentColor.withOpacity(0.1),
      );
      canvas.drawCircle(
        feedbackPos!,
        40,
        Paint()..color = accentColor.withOpacity(0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TouchpadPainter oldDelegate) =>
      oldDelegate.feedbackPos != feedbackPos ||
      oldDelegate.isDark != isDark;
}