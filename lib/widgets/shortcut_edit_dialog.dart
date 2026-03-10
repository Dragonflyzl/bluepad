import 'package:flutter/material.dart';
import '../models/shortcut_key.dart';
import '../models/shortcut_profile.dart';
import '../theme/app_colors.dart';

/// 快捷键编辑对话框
class ShortcutEditDialog extends StatefulWidget {
  final ShortcutKey? shortcut;  // null 表示新增
  final String platform;        // 'windows' 或 'macos'
  final String app;             // 'global', 'vscode' 等
  final Function(ShortcutKey) onSave;

  const ShortcutEditDialog({
    super.key,
    this.shortcut,
    required this.platform,
    required this.app,
    required this.onSave,
  });

  /// 显示对话框的静态方法
  static Future<bool?> show(
    BuildContext context, {
    ShortcutKey? shortcut,
    required String platform,
    required String app,
    required Function(ShortcutKey) onSave,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ShortcutEditDialog(
        shortcut: shortcut,
        platform: platform,
        app: app,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ShortcutEditDialog> createState() => _ShortcutEditDialogState();
}

class _ShortcutEditDialogState extends State<ShortcutEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _iconController;
  int _modifiers = 0;
  int _keyCode = 0;

  // 修饰键状态
  bool _ctrl = false;
  bool _shift = false;
  bool _alt = false;
  bool _gui = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shortcut?.name ?? '');
    _iconController = TextEditingController(text: widget.shortcut?.icon ?? '⌨');
    _modifiers = widget.shortcut?.modifiers ?? 0;
    _keyCode = widget.shortcut?.keyCode ?? 0;

    // 解析修饰键
    _ctrl = (_modifiers & HidModifiers.leftCtrl) != 0;
    _shift = (_modifiers & HidModifiers.leftShift) != 0;
    _alt = (_modifiers & HidModifiers.leftAlt) != 0;
    _gui = (_modifiers & HidModifiers.leftGui) != 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _updateModifiers() {
    _modifiers = 0;
    if (_ctrl) _modifiers |= HidModifiers.leftCtrl;
    if (_shift) _modifiers |= HidModifiers.leftShift;
    if (_alt) _modifiers |= HidModifiers.leftAlt;
    if (_gui) _modifiers |= HidModifiers.leftGui;
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入快捷键名称')),
      );
      return;
    }

    if (_keyCode == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一个按键')),
      );
      return;
    }

    final shortcut = ShortcutKey(
      id: widget.shortcut?.id ?? '${widget.platform}_${widget.app}_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text,
      icon: _iconController.text.isNotEmpty ? _iconController.text : '⌨',
      modifiers: _modifiers,
      keyCode: _keyCode,
      position: widget.shortcut?.position ?? 0,
      platform: widget.platform,
      app: widget.app,
    );

    widget.onSave(shortcut);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarkColors.bg1 : LightColors.bg1;
    final textColor = isDark ? DarkColors.text : LightColors.text;
    final hintColor = isDark ? DarkColors.text2 : LightColors.text2;
    final borderColor = isDark ? DarkColors.border : LightColors.border;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;

    final isMac = widget.platform == 'macos';

    return AlertDialog(
      backgroundColor: bgColor,
      title: Text(
        widget.shortcut == null ? '添加快捷键' : '编辑快捷键',
        style: TextStyle(color: textColor),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示当前系统和面板
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      '${isMac ? 'macOS' : 'Windows'} · ${_getAppName(widget.app)}',
                      style: TextStyle(color: accentColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 名称输入框
              TextField(
                controller: _nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: '快捷键名称',
                  labelStyle: TextStyle(color: hintColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: accentColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 图标输入框
              TextField(
                controller: _iconController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: '图标 (emoji)',
                  labelStyle: TextStyle(color: hintColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: accentColor)),
                ),
              ),
              const SizedBox(height: 20),

              // 修饰键选择
              Text(
                '修饰键',
                style: TextStyle(color: hintColor, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildModifierChip(
                    isMac ? '⌃ Ctrl' : 'Ctrl',
                    _ctrl,
                    (v) { setState(() { _ctrl = v; _updateModifiers(); }); },
                  ),
                  _buildModifierChip('⇧ Shift', _shift, (v) {
                    setState(() { _shift = v; _updateModifiers(); });
                  }),
                  _buildModifierChip(
                    isMac ? '⌥ Alt' : 'Alt',
                    _alt,
                    (v) { setState(() { _alt = v; _updateModifiers(); }); },
                  ),
                  _buildModifierChip(
                    isMac ? '⌘ Cmd' : '⊞ Win',
                    _gui,
                    (v) { setState(() { _gui = v; _updateModifiers(); }); },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 按键选择
              Text(
                '按键',
                style: TextStyle(color: hintColor, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _KeySelector(
                selectedKeyCode: _keyCode,
                onKeySelected: (code) => setState(() => _keyCode = code),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('取消', style: TextStyle(color: hintColor)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
          ),
          child: const Text('保存', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  String _getAppName(String appId) {
    final panels = AppPanel.getDefaults();
    final panel = panels.firstWhere((p) => p.id == appId, orElse: () => panels.first);
    return panel.name;
  }

  Widget _buildModifierChip(String label, bool selected, Function(bool) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final bgColor = isDark ? DarkColors.bg3 : LightColors.bg3;
    final borderColor = isDark ? DarkColors.border : LightColors.border;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      selectedColor: accentColor.withOpacity(0.2),
      checkmarkColor: accentColor,
      backgroundColor: bgColor,
      side: BorderSide(color: selected ? accentColor : borderColor),
      labelStyle: TextStyle(
        color: selected ? accentColor : (isDark ? DarkColors.text2 : LightColors.text2),
      ),
    );
  }
}

/// 按键选择器
class _KeySelector extends StatelessWidget {
  final int selectedKeyCode;
  final Function(int) onKeySelected;

  const _KeySelector({
    required this.selectedKeyCode,
    required this.onKeySelected,
  });

  // 常用按键列表
  static const _keys = [
    // 字母键
    {'code': 0x04, 'name': 'A'}, {'code': 0x05, 'name': 'B'},
    {'code': 0x06, 'name': 'C'}, {'code': 0x07, 'name': 'D'},
    {'code': 0x08, 'name': 'E'}, {'code': 0x09, 'name': 'F'},
    {'code': 0x0A, 'name': 'G'}, {'code': 0x0B, 'name': 'H'},
    {'code': 0x0C, 'name': 'I'}, {'code': 0x0D, 'name': 'J'},
    {'code': 0x0E, 'name': 'K'}, {'code': 0x0F, 'name': 'L'},
    {'code': 0x10, 'name': 'M'}, {'code': 0x11, 'name': 'N'},
    {'code': 0x12, 'name': 'O'}, {'code': 0x13, 'name': 'P'},
    {'code': 0x14, 'name': 'Q'}, {'code': 0x15, 'name': 'R'},
    {'code': 0x16, 'name': 'S'}, {'code': 0x17, 'name': 'T'},
    {'code': 0x18, 'name': 'U'}, {'code': 0x19, 'name': 'V'},
    {'code': 0x1A, 'name': 'W'}, {'code': 0x1B, 'name': 'X'},
    {'code': 0x1C, 'name': 'Y'}, {'code': 0x1D, 'name': 'Z'},
    // 数字键
    {'code': 0x1E, 'name': '1'}, {'code': 0x1F, 'name': '2'},
    {'code': 0x20, 'name': '3'}, {'code': 0x21, 'name': '4'},
    {'code': 0x22, 'name': '5'}, {'code': 0x23, 'name': '6'},
    {'code': 0x24, 'name': '7'}, {'code': 0x25, 'name': '8'},
    {'code': 0x26, 'name': '9'}, {'code': 0x27, 'name': '0'},
    // 控制键
    {'code': 0x28, 'name': 'Enter'}, {'code': 0x29, 'name': 'Esc'},
    {'code': 0x2A, 'name': '⌫'}, {'code': 0x2B, 'name': 'Tab'},
    {'code': 0x2C, 'name': 'Space'},
    // 符号键
    {'code': 0x2D, 'name': '-'}, {'code': 0x2E, 'name': '='},
    {'code': 0x2F, 'name': '['}, {'code': 0x30, 'name': ']'},
    {'code': 0x31, 'name': '\\'}, {'code': 0x33, 'name': ';'},
    {'code': 0x34, 'name': "'"}, {'code': 0x35, 'name': '`'},
    {'code': 0x36, 'name': ','}, {'code': 0x37, 'name': '.'},
    {'code': 0x38, 'name': '/'},
    // 功能键
    {'code': 0x3A, 'name': 'F1'}, {'code': 0x3B, 'name': 'F2'},
    {'code': 0x3C, 'name': 'F3'}, {'code': 0x3D, 'name': 'F4'},
    {'code': 0x3E, 'name': 'F5'}, {'code': 0x3F, 'name': 'F6'},
    {'code': 0x40, 'name': 'F7'}, {'code': 0x41, 'name': 'F8'},
    {'code': 0x42, 'name': 'F9'}, {'code': 0x43, 'name': 'F10'},
    {'code': 0x44, 'name': 'F11'}, {'code': 0x45, 'name': 'F12'},
    // 导航键
    {'code': 0x4A, 'name': 'Home'}, {'code': 0x4D, 'name': 'End'},
    {'code': 0x4B, 'name': 'PgUp'}, {'code': 0x4E, 'name': 'PgDn'},
    // 方向键和删除键
    {'code': 0x49, 'name': 'Ins'}, {'code': 0x4C, 'name': 'Del'},
    {'code': 0x4F, 'name': '→'}, {'code': 0x50, 'name': '←'},
    {'code': 0x51, 'name': '↓'}, {'code': 0x52, 'name': '↑'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarkColors.bg3 : LightColors.bg3;
    final borderColor = isDark ? DarkColors.border : LightColors.border;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final textColor = isDark ? DarkColors.text : LightColors.text;

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _keys.map((key) {
            final code = key['code'] as int;
            final isSelected = selectedKeyCode == code;
            return GestureDetector(
              onTap: () => onKeySelected(code),
              child: Container(
                width: key['name'].toString().length > 2 ? 48 : 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : bgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? accentColor : borderColor,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  key['name'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 删除确认对话框
class DeleteConfirmationDialog extends StatelessWidget {
  final String itemName;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.itemName,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String itemName,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        itemName: itemName,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarkColors.bg1 : LightColors.bg1;
    final textColor = isDark ? DarkColors.text : LightColors.text;
    final hintColor = isDark ? DarkColors.text2 : LightColors.text2;

    return AlertDialog(
      backgroundColor: bgColor,
      title: Text(
        '删除快捷键',
        style: TextStyle(color: textColor),
      ),
      content: Text(
        '确定要删除 "$itemName" 吗？此操作无法撤销。',
        style: TextStyle(color: hintColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('取消', style: TextStyle(color: hintColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () {
            onConfirm();
            Navigator.pop(context, true);
          },
          child: const Text('删除', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}