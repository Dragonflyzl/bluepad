import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shortcut_key.dart';
import '../models/shortcut_profile.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/shortcut_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/connection_bar.dart';
import '../widgets/shortcut_edit_dialog.dart';
import '../theme/app_colors.dart';
import '../utils/l10n_utils.dart';

class ShortcutsScreen extends ConsumerStatefulWidget {
  const ShortcutsScreen({super.key});

  @override
  ConsumerState<ShortcutsScreen> createState() => _ShortcutsScreenState();
}

class _ShortcutsScreenState extends ConsumerState<ShortcutsScreen> {
  String _currentProfileId = 'global';

  @override
  Widget build(BuildContext context) {
    // 使用 Provider 替代 getDefaults()
    final profiles = ref.watch(profilesProvider);
    final allShortcuts = ref.watch(shortcutsProvider);
    final shortcuts = allShortcuts.where((s) => _currentProfileId == 'global' || s.profile == _currentProfileId).toList();

    final shortcutsNotifier = ref.read(shortcutsProvider.notifier);
    final profilesNotifier = ref.read(profilesProvider.notifier);

    final actions = ref.read(bluetoothActionsProvider);
    final settings = ref.watch(settingsProvider);

    // 使用 settings.osType 替代设备名称判断
    final isMac = settings.osType == "macOS";

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Selector
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profiles.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemBuilder: (context, index) {
                if (index < profiles.length) {
                  final profile = profiles[index];
                  // 对齐原生：这里 profile.name 应该也有本地化映射，但目前先根据 ID 映射
                  String label = "${profile.icon} ${profile.name}";
                  if (profile.id == 'global') label = "${profile.icon} ${context.s('sc_profile_global')}";
                  
                  return _ProfileChip(
                    label: label,
                    isSelected: _currentProfileId == profile.id,
                    onTap: () => setState(() => _currentProfileId = profile.id),
                  );
                } else {
                  return _AddProfileBtn(onTap: () => _showAddProfileDialog(profilesNotifier));
                }
              },
            ),
          ),

          Text(
            context.s('sc_panel_title'),
            style: TextStyle(
              color: onSurfaceVariant,
              fontSize: 10,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Shortcuts Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.2,
              ),
              itemCount: shortcuts.length + 1,
              itemBuilder: (context, index) {
                if (index < shortcuts.length) {
                  final shortcut = shortcuts[index];
                  return _ShortcutGridItem(
                    shortcut: shortcut,
                    isMac: isMac,
                    onTap: () {
                      // 自动转换 Ctrl 为 Cmd (针对 Mac)
                      int mods = shortcut.modifiers;
                      if (isMac && (mods & 0x01 != 0)) {
                        mods = (mods & ~0x01) | 0x08;
                      }
                      actions.sendKeyPress(mods, [shortcut.keyCode]);
                    },
                    onLongPress: () => _showEditShortcutDialog(shortcut, shortcutsNotifier),
                  );
                } else {
                  return _AddShortcutItem(onTap: () => _showAddShortcutDialog(shortcutsNotifier));
                }
              },
            ),
          ),

          const SizedBox(height: 12),

          Text(
            context.s('sc_media_control'),
            style: TextStyle(
              color: onSurfaceVariant,
              fontSize: 10,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Media Control Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MediaButton(icon: Icons.volume_mute, label: context.s('sc_media_mute'), onTap: () => actions.sendConsumerReport(0x10)),
              _MediaButton(icon: Icons.volume_down, label: context.s('sc_media_vol_down'), onTap: () => actions.sendConsumerReport(0x40)),
              _MediaButton(icon: Icons.volume_up, label: context.s('sc_media_vol_up'), onTap: () => actions.sendConsumerReport(0x20)),
              _MediaButton(icon: Icons.skip_previous, label: context.s('sc_media_prev'), onTap: () => actions.sendConsumerReport(0x02)),
              _MediaButton(icon: Icons.play_arrow, label: context.s('sc_media_play'), onTap: () => actions.sendConsumerReport(0x08)),
              _MediaButton(icon: Icons.skip_next, label: context.s('sc_media_next'), onTap: () => actions.sendConsumerReport(0x01)),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 显示添加快捷键对话框
  void _showAddShortcutDialog(ShortcutsNotifier notifier) async {
    await ShortcutEditDialog.show(
      context,
      profileId: _currentProfileId,
      onSave: (shortcut) => notifier.addShortcut(shortcut),
    );
  }

  /// 显示编辑/删除快捷键菜单
  void _showEditShortcutDialog(ShortcutKey shortcut, ShortcutsNotifier notifier) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  ShortcutEditDialog.show(
                    context,
                    shortcut: shortcut,
                    profileId: _currentProfileId,
                    onSave: (s) => notifier.updateShortcut(s),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  DeleteConfirmationDialog.show(
                    context,
                    itemName: shortcut.name,
                    onConfirm: () => notifier.deleteShortcut(shortcut.id),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('取消'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示添加配置文件对话框
  void _showAddProfileDialog(ProfilesNotifier notifier) async {
    final nameController = TextEditingController();
    final iconController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? DarkColors.bg1 : LightColors.bg1;
        final textColor = isDark ? DarkColors.text : LightColors.text;
        final hintColor = isDark ? DarkColors.text2 : LightColors.text2;
        final borderColor = isDark ? DarkColors.border : LightColors.border;
        final accentColor = isDark ? DarkColors.accent : LightColors.primary;

        return AlertDialog(
          backgroundColor: bgColor,
          title: Text('添加配置', style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: '配置名称',
                  labelStyle: TextStyle(color: hintColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: iconController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: '图标 (emoji)',
                  labelStyle: TextStyle(color: hintColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消', style: TextStyle(color: hintColor)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final profile = ShortcutProfile(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    icon: iconController.text.isNotEmpty ? iconController.text : '📁',
                  );
                  notifier.addProfile(profile);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('添加', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSelected ? (isDark ? DarkColors.accent : LightColors.primary) : (isDark ? DarkColors.bg3 : LightColors.bg3);
    final borderColor = isSelected ? (isDark ? DarkColors.accent : LightColors.primary) : (isDark ? DarkColors.border : LightColors.border);
    final textColor = isSelected ? Colors.white : (isDark ? DarkColors.text2 : LightColors.text2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: textColor, fontSize: 11)),
      ),
    );
  }
}

class _AddProfileBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddProfileBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? DarkColors.border : LightColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add, size: 18, color: isDark ? DarkColors.text2 : LightColors.text2),
      ),
    );
  }
}

class _ShortcutGridItem extends StatefulWidget {
  final ShortcutKey shortcut;
  final bool isMac;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ShortcutGridItem({required this.shortcut, required this.isMac, required this.onTap, required this.onLongPress});

  @override
  State<_ShortcutGridItem> createState() => _ShortcutGridItemState();
}

class _ShortcutGridItemState extends State<_ShortcutGridItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final surfaceColor = isDark ? DarkColors.bg2 : LightColors.bg2;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isPressed ? accentColor.withOpacity(0.1) : surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _isPressed ? accentColor : (isDark ? DarkColors.border : LightColors.border)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.shortcut.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              widget.shortcut.name,
              style: TextStyle(color: isDark ? DarkColors.text : LightColors.text, fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.shortcut.fullDisplayName,
              style: TextStyle(color: isDark ? DarkColors.text2 : LightColors.text2, fontSize: 9, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  String _getModifierSymbols(int modifiers, bool isMac) {
    String symbols = "";
    if (modifiers & 0x08 != 0) symbols += isMac ? "⌘" : "⊞"; 
    if (modifiers & 0x01 != 0) {
      if (isMac) symbols += "⌘";
      else symbols += "⌃";
    }
    if (modifiers & 0x04 != 0) symbols += isMac ? "⌥" : "⎇";
    if (modifiers & 0x02 != 0) symbols += "⇧";
    return symbols.isEmpty ? "Key" : symbols;
  }
}

class _AddShortcutItem extends StatelessWidget {
  final VoidCallback onTap;
  const _AddShortcutItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? DarkColors.border : LightColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add, color: isDark ? DarkColors.text2 : LightColors.text2),
      ),
    );
  }
}

class _MediaButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purpleColor = isDark ? DarkColors.purple : const Color(0xFFA855F7);

    return Expanded(
      child: InkWell(
        onTap: () {
          onTap();
          Future.delayed(const Duration(milliseconds: 50), () => ref.read(bluetoothActionsProvider).sendConsumerReport(0)); 
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: purpleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: purpleColor.withOpacity(0.25)),
              ),
              child: Icon(icon, size: 16, color: purpleColor),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: purpleColor, fontSize: 8, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}
