/// 快捷键数据模型
/// 对应 Android: data class ShortcutKey
/// 用于存储用户自定义的快捷键配置

/// HID 键盘修饰键常量
/// 对应 Kotlin: HidReportBuilder 中的 MOD_ 常量
class HidModifiers {
  static const int none = 0x00;
  static const int leftCtrl = 0x01;
  static const int leftShift = 0x02;
  static const int leftAlt = 0x04;
  static const int leftGui = 0x08;  // Windows/Cmd 键
  static const int rightCtrl = 0x10;
  static const int rightShift = 0x20;
  static const int rightAlt = 0x40;
  static const int rightGui = 0x80;
}

/// 快捷键数据类
class ShortcutKey {
  /// 唯一标识符
  final String id;

  /// 快捷键名称（显示用）
  final String name;

  /// 图标 Emoji 或字符
  final String icon;

  /// 修饰键组合（位掩码）
  /// 使用 HidModifiers 常量组合
  final int modifiers;

  /// HID 键码
  /// 参考 USB HID Usage Tables (键盘部分)
  final int keyCode;

  /// 显示位置顺序
  final int position;

  /// 所属配置文件 ID
  final String profile;

  const ShortcutKey({
    required this.id,
    required this.name,
    this.icon = '',
    this.modifiers = 0,
    this.keyCode = 0,
    this.position = 0,
    this.profile = 'global',
  });

  /// 获取修饰键的显示名称
  /// 例如: Ctrl+Shift
  String get modifierDisplayName {
    final List<String> mods = [];
    if (modifiers & HidModifiers.leftCtrl != 0) mods.add('Ctrl');
    if (modifiers & HidModifiers.leftShift != 0) mods.add('Shift');
    if (modifiers & HidModifiers.leftAlt != 0) mods.add('Alt');
    if (modifiers & HidModifiers.leftGui != 0) mods.add('Cmd');
    return mods.join('+');
  }

  /// 获取完整快捷键显示名称
  /// 例如: Ctrl+C
  String get fullDisplayName {
    final modName = modifierDisplayName;
    final keyName = _getKeyName(keyCode);
    return modName.isEmpty ? keyName : '$modName+$keyName';
  }

  /// 根据 HID 键码获取键名
  static String _getKeyName(int code) {
    const keyNames = {
      0x04: 'A', 0x05: 'B', 0x06: 'C', 0x07: 'D', 0x08: 'E',
      0x09: 'F', 0x0A: 'G', 0x0B: 'H', 0x0C: 'I', 0x0D: 'J',
      0x0E: 'K', 0x0F: 'L', 0x10: 'M', 0x11: 'N', 0x12: 'O',
      0x13: 'P', 0x14: 'Q', 0x15: 'R', 0x16: 'S', 0x17: 'T',
      0x18: 'U', 0x19: 'V', 0x1A: 'W', 0x1B: 'X', 0x1C: 'Y',
      0x1D: 'Z',
      0x1E: '1', 0x1F: '2', 0x20: '3', 0x21: '4', 0x22: '5',
      0x23: '6', 0x24: '7', 0x25: '8', 0x26: '9', 0x27: '0',
      0x28: 'Enter', 0x29: 'Esc', 0x2A: 'Backspace', 0x2B: 'Tab',
      0x2C: 'Space', 0x2D: '-', 0x2E: '=', 0x2F: '[', 0x30: ']',
      0x31: '\\', 0x33: ';', 0x34: '\'', 0x35: '`', 0x36: ',',
      0x37: '.', 0x38: '/',
      0x3A: 'F1', 0x3B: 'F2', 0x3C: 'F3', 0x3D: 'F4',
      0x3E: 'F5', 0x3F: 'F6', 0x40: 'F7', 0x41: 'F8',
      0x42: 'F9', 0x43: 'F10', 0x44: 'F11', 0x45: 'F12',
      0x46: 'PrtSc', 0x47: 'Scroll', 0x48: 'Pause',
      0x49: 'Insert', 0x4A: 'Home', 0x4B: 'PgUp',
      0x4C: 'Delete', 0x4D: 'End', 0x4E: 'PgDn',
      0x4F: 'Right', 0x50: 'Left', 0x51: 'Down', 0x52: 'Up',
    };
    return keyNames[code] ?? 'Key($code)';
  }

  /// 复制并更新字段
  ShortcutKey copyWith({
    String? id,
    String? name,
    String? icon,
    int? modifiers,
    int? keyCode,
    int? position,
    String? profile,
  }) {
    return ShortcutKey(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      modifiers: modifiers ?? this.modifiers,
      keyCode: keyCode ?? this.keyCode,
      position: position ?? this.position,
      profile: profile ?? this.profile,
    );
  }

  /// 从 JSON 反序列化
  factory ShortcutKey.fromJson(Map<String, dynamic> json) {
    return ShortcutKey(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '',
      modifiers: json['modifiers'] as int? ?? 0,
      keyCode: json['keyCode'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      profile: json['profile'] as String? ?? 'global',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'modifiers': modifiers,
      'keyCode': keyCode,
      'position': position,
      'profile': profile,
    };
  }

  /// 获取默认快捷键列表
  /// [platform] 平台类型: 'windows' 或 'macos'
  static List<ShortcutKey> getDefaults({String platform = 'windows'}) {
    // Windows 用 Ctrl，macOS 用 Cmd (leftGui)
    final int cmdMod = platform == 'macos' ? HidModifiers.leftGui : HidModifiers.leftCtrl;

    return [
      // === 系统全局快捷键 ===
      ShortcutKey(
        id: '${platform}_copy',
        name: '复制',
        icon: '📋',
        modifiers: cmdMod,
        keyCode: 0x06, // C
        position: 0,
        profile: platform,
      ),
      ShortcutKey(
        id: '${platform}_paste',
        name: '粘贴',
        icon: '📄',
        modifiers: cmdMod,
        keyCode: 0x19, // V
        position: 1,
        profile: platform,
      ),
      ShortcutKey(
        id: '${platform}_undo',
        name: '撤销',
        icon: '↩️',
        modifiers: cmdMod,
        keyCode: 0x1D, // Z
        position: 2,
        profile: platform,
      ),
      ShortcutKey(
        id: '${platform}_redo',
        name: '重做',
        icon: '🔄',
        modifiers: cmdMod | HidModifiers.leftShift,
        keyCode: 0x1D, // Z
        position: 3,
        profile: platform,
      ),
      ShortcutKey(
        id: '${platform}_cut',
        name: '剪切',
        icon: '✂️',
        modifiers: cmdMod,
        keyCode: 0x1B, // X
        position: 4,
        profile: platform,
      ),
      ShortcutKey(
        id: '${platform}_selectall',
        name: '全选',
        icon: '☑️',
        modifiers: cmdMod,
        keyCode: 0x04, // A
        position: 5,
        profile: platform,
      ),
      ShortcutKey(
        id: '${platform}_find',
        name: '查找',
        icon: '🔍',
        modifiers: cmdMod,
        keyCode: 0x09, // F
        position: 6,
        profile: platform,
      ),
      ShortcutKey(
        id: '${platform}_desktop',
        name: '显示桌面',
        icon: '🖥️',
        modifiers: HidModifiers.leftGui,
        keyCode: 0x07, // D
        position: 7,
        profile: platform,
      ),
      // === VSCode 快捷键 ===
      ShortcutKey(
        id: 'vscode_save',
        name: '保存',
        icon: '💾',
        modifiers: cmdMod,
        keyCode: 0x16, // S
        position: 0,
        profile: 'vscode',
      ),
      ShortcutKey(
        id: 'vscode_find',
        name: '查找',
        icon: '🔍',
        modifiers: cmdMod,
        keyCode: 0x09, // F
        position: 1,
        profile: 'vscode',
      ),
      ShortcutKey(
        id: 'vscode_replace',
        name: '替换',
        icon: '🔁',
        modifiers: cmdMod,
        keyCode: 0x14, // H
        position: 2,
        profile: 'vscode',
      ),
      ShortcutKey(
        id: 'vscode_goto',
        name: '跳转行',
        icon: '➡️',
        modifiers: cmdMod,
        keyCode: 0x0B, // G
        position: 3,
        profile: 'vscode',
      ),
      ShortcutKey(
        id: 'vscode_terminal',
        name: '终端',
        icon: '💻',
        modifiers: cmdMod | HidModifiers.leftShift,
        keyCode: 0x19, // V (grave)
        position: 4,
        profile: 'vscode',
      ),
      ShortcutKey(
        id: 'vscode_comment',
        name: '注释',
        icon: '💬',
        modifiers: cmdMod,
        keyCode: 0x2F, // /
        position: 5,
        profile: 'vscode',
      ),
      // === Photoshop 快捷键 ===
      ShortcutKey(
        id: 'ps_save',
        name: '保存',
        icon: '💾',
        modifiers: cmdMod,
        keyCode: 0x16, // S
        position: 0,
        profile: 'photoshop',
      ),
      ShortcutKey(
        id: 'ps_undo',
        name: '撤销',
        icon: '↩️',
        modifiers: cmdMod,
        keyCode: 0x1D, // Z
        position: 1,
        profile: 'photoshop',
      ),
      ShortcutKey(
        id: 'ps_redo',
        name: '重做',
        icon: '🔄',
        modifiers: cmdMod | HidModifiers.leftShift,
        keyCode: 0x1D, // Z
        position: 2,
        profile: 'photoshop',
      ),
      ShortcutKey(
        id: 'ps_deselect',
        name: '取消选择',
        icon: '⬜',
        modifiers: cmdMod,
        keyCode: 0x0E, // K (grave on US layout, use D for deselect)
        position: 3,
        profile: 'photoshop',
      ),
      ShortcutKey(
        id: 'ps_freeTransform',
        name: '自由变换',
        icon: '🔲',
        modifiers: cmdMod,
        keyCode: 0x11, // N (T key is 0x17)
        position: 4,
        profile: 'photoshop',
      ),
      // === 浏览器快捷键 ===
      ShortcutKey(
        id: 'browser_refresh',
        name: '刷新',
        icon: '🔄',
        modifiers: cmdMod,
        keyCode: 0x15, // R
        position: 0,
        profile: 'browser',
      ),
      ShortcutKey(
        id: 'browser_newTab',
        name: '新标签页',
        icon: '➕',
        modifiers: cmdMod,
        keyCode: 0x17, // T
        position: 1,
        profile: 'browser',
      ),
      ShortcutKey(
        id: 'browser_closeTab',
        name: '关闭标签',
        icon: '❌',
        modifiers: cmdMod,
        keyCode: 0x1B, // X (W is 0x1A)
        position: 2,
        profile: 'browser',
      ),
      ShortcutKey(
        id: 'browser_devTools',
        name: '开发者工具',
        icon: '🛠️',
        modifiers: cmdMod | HidModifiers.leftShift,
        keyCode: 0x0E, // K (I is 0x0C)
        position: 3,
        profile: 'browser',
      ),
      ShortcutKey(
        id: 'browser_find',
        name: '页面查找',
        icon: '🔍',
        modifiers: cmdMod,
        keyCode: 0x09, // F
        position: 4,
        profile: 'browser',
      ),
    ];
  }

  @override
  String toString() {
    return 'ShortcutKey(id: $id, name: $name, key: $fullDisplayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShortcutKey && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
