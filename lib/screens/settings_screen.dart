import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../utils/l10n_utils.dart';

/// 设置屏幕
/// 对应 Android: SettingsScreenNew.kt
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      children: [
        // Touchpad Settings
        _SettingGroup(
          title: context.s('settings_group_touchpad'),
          children: [
            _SettingSlider(
              label: context.s('settings_sensitivity'),
              value: settings.sensitivity,
              min: 0.5,
              max: 5.0,
              onChanged: (v) => notifier.setSensitivity(v),
              displayValue: "${settings.sensitivity.toStringAsFixed(1)}x",
            ),
            _SettingSlider(
              label: context.s('settings_scroll_speed'),
              value: settings.scrollSensitivity,
              min: 0.5,
              max: 5.0,
              onChanged: (v) => notifier.setScrollSensitivity(v),
              displayValue: "${settings.scrollSensitivity.toStringAsFixed(1)}x",
            ),
            _SettingToggle(
              label: context.s('settings_tap_to_click'),
              desc: context.s('settings_tap_to_click_desc'),
              value: settings.tapToClick,
              onChanged: (v) => notifier.setTapToClick(v),
            ),
            _SettingToggle(
              label: context.s('settings_natural_scroll'),
              desc: context.s('settings_natural_scroll_desc'),
              value: settings.naturalScroll,
              onChanged: (v) => notifier.setNaturalScroll(v),
            ),
            _SettingToggle(
              label: context.s('settings_inertia'),
              desc: context.s('settings_inertia_desc'),
              value: settings.inertia,
              onChanged: (v) => notifier.setInertia(v),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Keyboard Settings
        _SettingGroup(
          title: context.s('settings_group_keyboard'),
          children: [
            _SettingToggle(
              label: context.s('settings_mac_mode'),
              desc: context.s('settings_mac_mode_desc'),
              value: settings.osType == "macOS",
              onChanged: (v) => notifier.setOsType(v ? "macOS" : "Windows"),
            ),
            _SettingToggle(
              label: context.s('settings_haptic'),
              desc: context.s('settings_haptic_desc'),
              value: settings.haptic,
              onChanged: (v) => notifier.setHaptic(v),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Clipboard Settings
        _SettingGroup(
          title: context.s('cb_settings_title'),
          children: [
            _SettingToggle(
              label: context.s('cb_auto_sync'),
              desc: context.s('cb_auto_sync_desc'),
              value: settings.clipboardAutoSync,
              onChanged: (v) => notifier.setClipboardAutoSync(v),
            ),
            _SettingToggle(
              label: context.s('cb_sensitive_filter'),
              desc: context.s('cb_sensitive_filter_desc'),
              value: settings.clipboardSensitiveDetection,
              onChanged: (v) => notifier.setClipboardSensitiveDetection(v),
            ),
            _SettingToggle(
              label: context.s('cb_save_history'),
              desc: context.s('cb_save_history_desc'),
              value: settings.clipboardSaveHistory,
              onChanged: (v) => notifier.setClipboardSaveHistory(v),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // General Settings
        _SettingGroup(
          title: context.s('settings_group_general'),
          children: [
            _SettingItem(
              label: context.s('settings_theme'),
              desc: settings.themeMode == "auto" ? context.s('theme_auto') : (settings.themeMode == "dark" ? context.s('theme_dark') : context.s('theme_light')),
              onTap: () => _showThemePicker(context, settings.themeMode, notifier),
            ),
            _SettingItem(
              label: context.s('settings_language'),
              desc: settings.language == "zh" ? "简体中文" : "English",
              onTap: () => _showLanguagePicker(context, settings.language, notifier),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Data Management
        _SettingGroup(
          title: context.s('settings_group_data'),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: _Button(label: context.s('settings_export'), onTap: () {}),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Button(label: context.s('settings_import'), onTap: () {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showThemePicker(BuildContext context, String current, SettingsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(context.s('theme_light')),
                trailing: current == "light" ? const Icon(Icons.check, color: DarkColors.accent) : null,
                onTap: () { notifier.setThemeMode("light"); Navigator.pop(context); },
              ),
              ListTile(
                title: Text(context.s('theme_dark')),
                trailing: current == "dark" ? const Icon(Icons.check, color: DarkColors.accent) : null,
                onTap: () { notifier.setThemeMode("dark"); Navigator.pop(context); },
              ),
              ListTile(
                title: Text(context.s('theme_auto')),
                trailing: current == "auto" ? const Icon(Icons.check, color: DarkColors.accent) : null,
                onTap: () { notifier.setThemeMode("auto"); Navigator.pop(context); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, String current, SettingsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("简体中文"),
                trailing: current == "zh" ? const Icon(Icons.check, color: DarkColors.accent) : null,
                onTap: () { notifier.setLanguage("zh"); Navigator.pop(context); },
              ),
              ListTile(
                title: const Text("English"),
                trailing: current == "en" ? const Icon(Icons.check, color: DarkColors.accent) : null,
                onTap: () { notifier.setLanguage("en"); Navigator.pop(context); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariant = isDark ? DarkColors.bg3 : LightColors.bg3;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;

    return Container(
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 9,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ),
          Divider(height: 1, color: outlineColor),
          ...children,
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final String label;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({required this.label, required this.desc, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final onSurface = isDark ? DarkColors.text : LightColors.text;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;

    return Column(
      children: [
        InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: onSurface, fontSize: 12)),
                      Text(desc, style: TextStyle(color: onSurfaceVariant, fontSize: 9)),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: Colors.white,
                    activeTrackColor: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: outlineColor.withOpacity(0.5)),
      ],
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String displayValue;

  const _SettingSlider({required this.label, required this.value, required this.min, required this.max, required this.onChanged, required this.displayValue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final onSurface = isDark ? DarkColors.text : LightColors.text;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(color: onSurface, fontSize: 12)),
                  Text(displayValue, style: TextStyle(color: accentColor, fontSize: 10, fontFamily: 'monospace')),
                ],
              ),
              Slider(
                value: value,
                min: min,
                max: max,
                activeColor: accentColor,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: outlineColor.withOpacity(0.5)),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final String desc;
  final VoidCallback onTap;

  const _SettingItem({required this.label, required this.desc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? DarkColors.text : LightColors.text;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: onSurface, fontSize: 12)),
                      Text(desc, style: TextStyle(color: onSurfaceVariant, fontSize: 9)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 14, color: onSurfaceVariant),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: outlineColor.withOpacity(0.5)),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Button({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;
    final onSurface = isDark ? DarkColors.text : LightColors.text;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outlineColor),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: onSurface, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
