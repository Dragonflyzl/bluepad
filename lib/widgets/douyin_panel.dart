import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bluetooth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/l10n_utils.dart';

/// 抖音专用滑动手势面板
/// 上/下滑动切换视频、左/右滑动前进/后退
/// 底部按钮：关注(G)、喜欢(Z)、评论(X)
class DouyinPanel extends ConsumerStatefulWidget {
  final BluetoothActions actions;
  final bool isDark;

  const DouyinPanel({
    super.key,
    required this.actions,
    required this.isDark,
  });

  @override
  ConsumerState<DouyinPanel> createState() => _DouyinPanelState();
}

class _DouyinPanelState extends ConsumerState<DouyinPanel> {
  Offset _accumulatedDelta = Offset.zero;
  static const double _swipeThreshold = 50.0;

  void _sendKey(int modifiers, int keyCode) {
    widget.actions.sendKeyPress(modifiers, [keyCode]);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _accumulatedDelta += details.delta;
  }

  void _onPanEnd(DragEndDetails details) {
    final dx = _accumulatedDelta.dx;
    final dy = _accumulatedDelta.dy;
    _accumulatedDelta = Offset.zero;

    // 判断主方向：上下滑动 vs 左右滑动
    if (dy.abs() > dx.abs()) {
      // 上下滑动 — 切换视频
      if (dy < -_swipeThreshold) {
        _sendKey(0, 0x51); // Arrow Up → 下一个视频
        _triggerHaptic();
      } else if (dy > _swipeThreshold) {
        _sendKey(0, 0x52); // Arrow Down → 上一个视频
        _triggerHaptic();
      }
    } else {
      // 左右滑动 — 前进/后退
      if (dx < -_swipeThreshold) {
        _sendKey(0, 0x50); // Arrow Left → 后退
        _triggerHaptic();
      } else if (dx > _swipeThreshold) {
        _sendKey(0, 0x4F); // Arrow Right → 快进
        _triggerHaptic();
      }
    }
  }

  void _onPanCancel() {
    _accumulatedDelta = Offset.zero;
  }

  void _onTap() {
    // 单击滑动手势区域 → 发送空格键暂停/播放
    _sendKey(0, 0x2C);
    _triggerHaptic();
  }

  void _triggerHaptic() {
    widget.actions.vibrate(30);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDark ? const Color(0xFFEE2E6A) : const Color(0xFFFE2C55);
    final surfaceColor = widget.isDark ? DarkColors.bg2 : LightColors.bg2;
    final secondaryText = widget.isDark ? DarkColors.text2 : LightColors.text2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          // ======== 上部分：滑动手势区域 ========
          Expanded(
            child: GestureDetector(
              onTap: _onTap,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: _onPanCancel,
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 上滑提示
                    _DirectionHint(
                      icon: Icons.keyboard_arrow_up,
                      label: context.s('dy_up'),
                      color: accentColor,
                    ),
                    const SizedBox(height: 24),
                    // 中行：左滑 - 图标 - 右滑
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DirectionHint(
                          icon: Icons.keyboard_arrow_left,
                          label: context.s('dy_left'),
                          color: secondaryText,
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: accentColor,
                            size: 36,
                          ),
                        ),
                        _DirectionHint(
                          icon: Icons.keyboard_arrow_right,
                          label: context.s('dy_right'),
                          color: secondaryText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 下滑提示
                    _DirectionHint(
                      icon: Icons.keyboard_arrow_down,
                      label: context.s('dy_down'),
                      color: accentColor,
                    ),
                    const SizedBox(height: 12),
                    // 提示文字
                    Text(
                      context.s('dy_hint'),
                      style: TextStyle(
                        color: secondaryText.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ======== 下部分：操作按钮 ========
          Row(
            children: [
              _ActionButton(
                icon: Icons.person_add_outlined,
                label: context.s('dy_follow'),
                keyName: context.s('dy_key_g'),
                color: accentColor,
                onTap: () => _sendKey(0, 0x0A),
                isDark: widget.isDark,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.favorite_border,
                label: context.s('dy_like'),
                keyName: context.s('dy_key_z'),
                color: accentColor,
                onTap: () => _sendKey(0, 0x1D),
                isDark: widget.isDark,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: context.s('dy_comment'),
                keyName: context.s('dy_key_x'),
                color: accentColor,
                onTap: () => _sendKey(0, 0x1B),
                isDark: widget.isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 方向提示组件
class _DirectionHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DirectionHint({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 操作按钮组件
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String keyName;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.keyName,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  keyName,
                  style: TextStyle(
                    color: isDark ? DarkColors.text2 : LightColors.text2,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}