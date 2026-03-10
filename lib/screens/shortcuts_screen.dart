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

class _ShortcutsScreenState extends ConsumerState<ShortcutsScreen> with SingleTickerProviderStateMixin {
  late TabController _systemTabController;

  @override
  void initState() {
    super.initState();
    _systemTabController = TabController(length: 2, vsync: this);
    _systemTabController.addListener(_onSystemTabChanged);
  }

  @override
  void dispose() {
    _systemTabController.removeListener(_onSystemTabChanged);
    _systemTabController.dispose();
    super.dispose();
  }

  void _onSystemTabChanged() {
    if (!_systemTabController.indexIsChanging) {
      final system = _systemTabController.index == 0 ? 'windows' : 'macos';
      ref.read(currentSystemProvider.notifier).state = system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSystem = ref.watch(currentSystemProvider);
    // 同步 TabController 状态
    if (_systemTabController.index != (currentSystem == 'windows' ? 0 : 1)) {
      _systemTabController.animateTo(currentSystem == 'windows' ? 0 : 1);
    }

    final currentApp = ref.watch(currentAppProvider);
    final appPanels = ref.watch(appPanelsProvider);
    final shortcuts = ref.watch(filteredShortcutsProvider);

    final shortcutsNotifier = ref.read(shortcutsProvider.notifier);
    final panelsNotifier = ref.read(appPanelsProvider.notifier);

    final actions = ref.read(bluetoothActionsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;

    return Column(
      children: [
        // 系统 Tab 栏
        _buildSystemTabBar(context, isDark),

        // 软件面板选择器
        _buildAppPanelSelector(context, appPanels, currentApp, isDark, panelsNotifier),

        // 快捷键网格标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                context.s('sc_panel_title'),
                style: TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${shortcuts.length} ${context.s('sc_items')}',
                style: TextStyle(
                  color: onSurfaceVariant.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        // 快捷键网格
        Expanded(
          child: shortcuts.isEmpty
              ? _buildEmptyState(context, isDark)
              : _buildShortcutsGrid(context, shortcuts, currentSystem, actions, shortcutsNotifier, isDark),
        ),

        // 媒体控制
        _buildMediaControl(context, actions, isDark, onSurfaceVariant),
      ],
    );
  }

  /// 构建系统 Tab 栏
  Widget _buildSystemTabBar(BuildContext context, bool isDark) {
    final bgColor = isDark ? DarkColors.bg2 : LightColors.bg2;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final unselectedColor = isDark ? DarkColors.text2 : LightColors.text2;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _systemTabController,
        indicator: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: unselectedColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: '🪟 Windows'),
          Tab(text: '🍎 macOS'),
        ],
      ),
    );
  }

  /// 构建软件面板选择器
  Widget _buildAppPanelSelector(
    BuildContext context,
    List<AppPanel> appPanels,
    String currentApp,
    bool isDark,
    AppPanelsNotifier panelsNotifier,
  ) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: appPanels.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          if (index < appPanels.length) {
            final panel = appPanels[index];
            final isSelected = currentApp == panel.id;

            return _AppPanelChip(
              panel: panel,
              isSelected: isSelected,
              onTap: () => ref.read(currentAppProvider.notifier).state = panel.id,
            );
          } else {
            return _AddPanelBtn(
              onTap: () => _showAddPanelDialog(panelsNotifier),
            );
          }
        },
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final textColor = isDark ? DarkColors.text2 : LightColors.text2;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.keyboard, size: 48, color: textColor.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            context.s('sc_no_shortcuts'),
            style: TextStyle(color: textColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  /// 构建快捷键网格
  Widget _buildShortcutsGrid(
    BuildContext context,
    List<ShortcutKey> shortcuts,
    String currentSystem,
    BluetoothActions actions,
    ShortcutsNotifier shortcutsNotifier,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
              isMac: currentSystem == 'macos',
              onTap: () => _sendShortcut(actions, shortcut, currentSystem),
              onLongPress: () => _showEditShortcutDialog(shortcut, shortcutsNotifier),
            );
          } else {
            return _AddShortcutItem(
              onTap: () => _showAddShortcutDialog(shortcutsNotifier),
            );
          }
        },
      ),
    );
  }

  /// 构建媒体控制
  Widget _buildMediaControl(
    BuildContext context,
    BluetoothActions actions,
    bool isDark,
    Color onSurfaceVariant,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  /// 发送快捷键
  void _sendShortcut(BluetoothActions actions, ShortcutKey shortcut, String currentSystem) {
    // 直接使用快捷键的修饰键发送
    actions.sendKeyPress(shortcut.modifiers, [shortcut.keyCode]);
  }

  /// 显示添加快捷键对话框
  void _showAddShortcutDialog(ShortcutsNotifier notifier) async {
    final currentSystem = ref.read(currentSystemProvider);
    final currentApp = ref.read(currentAppProvider);

    await ShortcutEditDialog.show(
      context,
      platform: currentSystem,
      app: currentApp,
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
                  final currentSystem = ref.read(currentSystemProvider);
                  final currentApp = ref.read(currentAppProvider);
                  ShortcutEditDialog.show(
                    context,
                    shortcut: shortcut,
                    platform: currentSystem,
                    app: currentApp,
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

  /// 显示添加软件面板对话框
  void _showAddPanelDialog(AppPanelsNotifier notifier) async {
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
          title: Text('添加软件面板', style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: '面板名称',
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
                  final panel = AppPanel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    icon: iconController.text.isNotEmpty ? iconController.text : '📁',
                  );
                  notifier.addPanel(panel);
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

/// 软件面板选择 Chip
class _AppPanelChip extends StatelessWidget {
  final AppPanel panel;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppPanelChip({required this.panel, required this.isSelected, required this.onTap});

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
        child: Text(
          '${panel.icon} ${panel.name}',
          style: TextStyle(color: textColor, fontSize: 11),
        ),
      ),
    );
  }
}

/// 添加面板按钮
class _AddPanelBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPanelBtn({required this.onTap});

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

/// 快捷键网格项
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
              widget.shortcut.fullDisplayNameFor(widget.shortcut.platform),
              style: TextStyle(color: isDark ? DarkColors.text2 : LightColors.text2, fontSize: 9, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加快捷键按钮
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

/// 媒体控制按钮
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