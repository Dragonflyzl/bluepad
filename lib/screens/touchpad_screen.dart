import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../widgets/touchpad_area.dart';
import '../utils/l10n_utils.dart';

/// 触控板屏幕
/// 对应 Android: TouchpadScreen.kt
class TouchpadScreen extends ConsumerWidget {
  const TouchpadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final actions = ref.read(bluetoothActionsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;

    return Column(
      children: [
        // Touchpad Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outlineColor, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: TouchPadArea(
                sensitivity: settings.sensitivity,
                scrollSensitivity: settings.scrollSensitivity,  // 添加滚动灵敏度
                tapToClick: settings.tapToClick,
                naturalScroll: settings.naturalScroll,
                inertia: settings.inertia,
                onMouseMove: (dx, dy, buttonMask) {
                  actions.sendMouseMove(dx, dy, buttons: buttonMask);
                },
                onMouseClick: (button) {
                  _sendClick(actions, button);
                },
                onScroll: (v, h) {
                  actions.sendScroll(v, horizontal: h);
                },
                onZoomStart: () => actions.sendZoom(0, isStart: true),
                onZoomUpdate: (delta) => actions.sendZoom(delta),
                onZoomEnd: () => actions.sendZoom(0, isEnd: true),
                onThreeFingerTap: () => actions.sendThreeFingerTap(),
                onThreeFingerSwipe: (direction) {
                  _handleThreeFingerSwipe(actions, direction);
                },
              ),
            ),
          ),
        ),

        // Bottom Button Bar
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MouseButton(
                label: context.s('touch_mouse_left'),
                flex: 2,
                onTap: () => _sendClick(actions, MouseButton.left),
              ),
              _MouseButton(
                label: context.s('touch_mouse_mid'),
                flex: 1,
                onTap: () => _sendClick(actions, MouseButton.middle),
              ),
              _MouseButton(
                label: context.s('touch_mouse_right'),
                flex: 2,
                onTap: () => _sendClick(actions, MouseButton.right),
              ),
            ],
          ),
        ),

        // Status Info
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 10, color: onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                "${context.s('settings_sensitivity')}: ${settings.sensitivity.toStringAsFixed(1)}x  ·  ${context.s('settings_scroll_speed')}: ${settings.scrollSensitivity.toStringAsFixed(1)}x",
                style: TextStyle(
                  color: onSurfaceVariant.withOpacity(0.6),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendClick(BluetoothActions actions, MouseButton button) {
    int btnMask = 0;
    switch (button) {
      case MouseButton.left: btnMask = 0x01; break;
      case MouseButton.right: btnMask = 0x02; break;
      case MouseButton.middle: btnMask = 0x04; break;
    }
    actions.sendMouseMove(0, 0, buttons: btnMask);
    Future.delayed(const Duration(milliseconds: 50), () {
      actions.sendMouseMove(0, 0, buttons: 0);
    });
  }

  void _handleThreeFingerSwipe(BluetoothActions actions, SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.up:
        actions.sendKeyPress(0x08, [0x52]); // Win+Up
        break;
      case SwipeDirection.down:
        actions.sendKeyPress(0x08, [0x51]); // Win+Down
        break;
      case SwipeDirection.left:
        actions.sendKeyPress(0x08, [0x50]); // Win+Left
        break;
      case SwipeDirection.right:
        actions.sendKeyPress(0x08, [0x4F]); // Win+Right
        break;
    }
  }
}

class _MouseButton extends StatelessWidget {
  final String label;
  final int flex;
  final VoidCallback onTap;

  const _MouseButton({required this.label, required this.flex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariant = isDark ? DarkColors.bg3 : LightColors.bg3;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: outlineColor),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
