import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/l10n_utils.dart';

class AirMouseScreen extends ConsumerStatefulWidget {
  const AirMouseScreen({super.key});

  @override
  ConsumerState<AirMouseScreen> createState() => _AirMouseScreenState();
}

class _AirMouseScreenState extends ConsumerState<AirMouseScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final sensorState = ref.watch(sensorProvider);
    final sensorNotifier = ref.read(sensorProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final bluetoothActions = ref.read(bluetoothActionsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final onSurface = isDark ? DarkColors.text : LightColors.text;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.s('air_mouse_mode'),
                    style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    sensorState.enabled ? context.s('air_mouse_moving') : context.s('air_mouse_off_hint'),
                    style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
              Switch(
                value: sensorState.enabled,
                onChanged: (v) => sensorNotifier.toggle(v),
                activeColor: accentColor,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sensitivity Slider
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? DarkColors.bg2 : LightColors.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.s('air_mouse_sensitivity'), style: TextStyle(color: onSurface, fontSize: 14)),
                    Text("${settings.sensitivity.toStringAsFixed(1)}x", 
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ],
                ),
                Slider(
                  value: settings.sensitivity,
                  min: 0.5,
                  max: 5.0,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setSensitivity(v),
                  activeColor: accentColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Interaction Area
          Expanded(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) {
                _isDragging = false;
                sensorNotifier.setClutch(true);
              },
              onPointerMove: (_) {
                if (!_isDragging) _isDragging = true;
              },
              onPointerUp: (_) {
                sensorNotifier.setClutch(false);
                // 只有没有移动才触发点击
                if (!_isDragging) {
                  _sendClick(bluetoothActions, MouseButton.left);
                }
              },
              onPointerCancel: (_) {
                sensorNotifier.setClutch(false);
              },
              child: GestureDetector(
                onDoubleTap: () {
                  _sendClick(bluetoothActions, MouseButton.left, doubleClick: true);
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: sensorState.isClutchPressed
                      ? accentColor.withOpacity(0.1)
                      : (isDark ? DarkColors.bg3 : LightColors.bg3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sensorState.isClutchPressed ? accentColor : outlineColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sensorState.isClutchPressed ? Icons.ads_click : Icons.touch_app,
                        size: 64,
                        color: sensorState.isClutchPressed ? accentColor : onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        sensorState.isClutchPressed ? context.s('air_mouse_moving') : context.s('air_mouse_hold_to_move'),
                        style: TextStyle(
                          color: sensorState.isClutchPressed ? accentColor : onSurfaceVariant,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.s('air_mouse_tap_hint'),
                        style: TextStyle(color: onSurfaceVariant.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Buttons
          Row(
            children: [
              _BigButton(
                label: context.s('air_mouse_left_btn'),
                color: accentColor,
                onTap: () => _sendClick(bluetoothActions, MouseButton.left),
              ),
              const SizedBox(width: 16),
              _BigButton(
                label: context.s('air_mouse_right_btn'),
                color: isDark ? DarkColors.purple : LightColors.purple,
                onTap: () => _sendClick(bluetoothActions, MouseButton.right),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Text(
            context.s('air_mouse_bottom_hint'),
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurfaceVariant.withOpacity(0.6), fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _sendClick(BluetoothActions actions, MouseButton button, {bool doubleClick = false}) {
    int mask = (button == MouseButton.left) ? 0x01 : 0x02;
    if (doubleClick) {
      actions.sendMouseMove(0, 0, buttons: mask);
      Future.delayed(const Duration(milliseconds: 50), () {
        actions.sendMouseMove(0, 0, buttons: 0);
        Future.delayed(const Duration(milliseconds: 50), () {
          actions.sendMouseMove(0, 0, buttons: mask);
          Future.delayed(const Duration(milliseconds: 50), () => actions.sendMouseMove(0, 0, buttons: 0));
        });
      });
    } else {
      actions.sendMouseMove(0, 0, buttons: mask);
      Future.delayed(const Duration(milliseconds: 50), () => actions.sendMouseMove(0, 0, buttons: 0));
    }
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
