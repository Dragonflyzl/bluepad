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
  static const int leftGui = 0x08; // Windows/Cmd 键
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

  /// 所属平台: 'windows' 或 'macos'
  final String platform;

  /// 所属应用面板: 'global', 'vscode', 'photoshop', 'browser' 等
  final String app;

  /// 兼容旧数据的 profile 字段（仅用于数据迁移）
  final String? legacyProfile;

  const ShortcutKey({
    required this.id,
    required this.name,
    this.icon = '',
    this.modifiers = 0,
    this.keyCode = 0,
    this.position = 0,
    this.platform = 'windows',
    this.app = 'global',
    this.legacyProfile,
  });

  /// 获取修饰键的显示名称
  /// 根据 platform 参数决定显示格式
  String modifierDisplayNameFor(String platform) {
    final List<String> mods = [];
    final isMac = platform == 'macos';

    if (modifiers & HidModifiers.leftGui != 0) {
      mods.add(isMac ? '⌘' : 'Win');
    }
    if (modifiers & HidModifiers.leftCtrl != 0) {
      mods.add(isMac ? '⌃' : 'Ctrl');
    }
    if (modifiers & HidModifiers.leftAlt != 0) {
      mods.add(isMac ? '⌥' : 'Alt');
    }
    if (modifiers & HidModifiers.leftShift != 0) {
      mods.add('⇧');
    }
    return mods.join('+');
  }

  /// 获取完整快捷键显示名称
  /// 例如: Ctrl+C 或 ⌘+C
  String fullDisplayNameFor(String platform) {
    final modName = modifierDisplayNameFor(platform);
    final keyName = _getKeyName(keyCode);
    return modName.isEmpty ? keyName : '$modName+$keyName';
  }

  /// 默认使用自身 platform 显示
  String get modifierDisplayName => modifierDisplayNameFor(platform);
  String get fullDisplayName => fullDisplayNameFor(platform);

  /// 根据 HID 键码获取键名
  static String _getKeyName(int code) {
    const keyNames = {
      0x04: 'A',
      0x05: 'B',
      0x06: 'C',
      0x07: 'D',
      0x08: 'E',
      0x09: 'F',
      0x0A: 'G',
      0x0B: 'H',
      0x0C: 'I',
      0x0D: 'J',
      0x0E: 'K',
      0x0F: 'L',
      0x10: 'M',
      0x11: 'N',
      0x12: 'O',
      0x13: 'P',
      0x14: 'Q',
      0x15: 'R',
      0x16: 'S',
      0x17: 'T',
      0x18: 'U',
      0x19: 'V',
      0x1A: 'W',
      0x1B: 'X',
      0x1C: 'Y',
      0x1D: 'Z',
      0x1E: '1',
      0x1F: '2',
      0x20: '3',
      0x21: '4',
      0x22: '5',
      0x23: '6',
      0x24: '7',
      0x25: '8',
      0x26: '9',
      0x27: '0',
      0x28: 'Enter',
      0x29: 'Esc',
      0x2A: 'Backspace',
      0x2B: 'Tab',
      0x2C: 'Space',
      0x2D: '-',
      0x2E: '=',
      0x2F: '[',
      0x30: ']',
      0x31: '\\',
      0x32: '\\',
      0x33: ';',
      0x34: '\'',
      0x35: '`',
      0x36: ',',
      0x37: '.',
      0x38: '/',
      0x3A: 'F1',
      0x3B: 'F2',
      0x3C: 'F3',
      0x3D: 'F4',
      0x3E: 'F5',
      0x3F: 'F6',
      0x40: 'F7',
      0x41: 'F8',
      0x42: 'F9',
      0x43: 'F10',
      0x44: 'F11',
      0x45: 'F12',
      0x46: 'PrtSc',
      0x47: 'Scroll',
      0x48: 'Pause',
      0x49: 'Insert',
      0x4A: 'Home',
      0x4B: 'PgUp',
      0x4C: 'Delete',
      0x4D: 'End',
      0x4E: 'PgDn',
      0x4F: 'Right',
      0x50: 'Left',
      0x51: 'Down',
      0x52: 'Up',
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
    String? platform,
    String? app,
    String? legacyProfile,
  }) {
    return ShortcutKey(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      modifiers: modifiers ?? this.modifiers,
      keyCode: keyCode ?? this.keyCode,
      position: position ?? this.position,
      platform: platform ?? this.platform,
      app: app ?? this.app,
      legacyProfile: legacyProfile ?? this.legacyProfile,
    );
  }

  /// 从 JSON 反序列化
  factory ShortcutKey.fromJson(Map<String, dynamic> json) {
    // 数据迁移：从旧的 profile 字段提取 platform 和 app
    String platform = json['platform'] as String? ?? 'windows';
    String app = json['app'] as String? ?? 'global';
    final legacyProfile = json['profile'] as String?;

    // 如果有旧的 profile 字段，尝试迁移
    if (legacyProfile != null && json['platform'] == null) {
      if (legacyProfile == 'windows' || legacyProfile == 'macos') {
        // 旧的系统 profile，映射为 global
        platform = legacyProfile;
        app = 'global';
      } else if (legacyProfile.startsWith('win_')) {
        platform = 'windows';
        app = legacyProfile.substring(4);
      } else if (legacyProfile.startsWith('mac_')) {
        platform = 'macos';
        app = legacyProfile.substring(4);
      } else {
        // 其他 profile（vscode, photoshop 等）默认为 windows
        app = legacyProfile;
      }
    }

    return ShortcutKey(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '',
      modifiers: json['modifiers'] as int? ?? 0,
      keyCode: json['keyCode'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      platform: platform,
      app: app,
      legacyProfile: legacyProfile,
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
      'platform': platform,
      'app': app,
    };
  }

  /// 获取默认快捷键列表
  /// 包含 Windows 和 macOS 两个平台的所有快捷键
  static List<ShortcutKey> getDefaults() {
    final List<ShortcutKey> shortcuts = [];

    // ==================== Windows 平台 ====================
    shortcuts.addAll(_getWindowsGlobalShortcuts());
    shortcuts.addAll(_getWindowsVscodeShortcuts());
    shortcuts.addAll(_getWindowsPhotoshopShortcuts());
    shortcuts.addAll(_getWindowsBrowserShortcuts());

    // ==================== macOS 平台 ====================
    shortcuts.addAll(_getMacosGlobalShortcuts());
    shortcuts.addAll(_getMacosVscodeShortcuts());
    shortcuts.addAll(_getMacosPhotoshopShortcuts());
    shortcuts.addAll(_getMacosBrowserShortcuts());

    return shortcuts;
  }

  // ==================== Windows 快捷键 ====================

  static List<ShortcutKey> _getWindowsGlobalShortcuts() {
    const cmd = HidModifiers.leftCtrl;
    return [
      ShortcutKey(
        id: 'win_global_copy',
        name: '复制',
        icon: '📋',
        modifiers: cmd,
        keyCode: 0x06,
        position: 0,
        platform: 'windows',
        app: 'global',
      ),
      ShortcutKey(
        id: 'win_global_paste',
        name: '粘贴',
        icon: '📄',
        modifiers: cmd,
        keyCode: 0x19,
        position: 1,
        platform: 'windows',
        app: 'global',
      ),
      ShortcutKey(
        id: 'win_global_undo',
        name: '撤销',
        icon: '↩️',
        modifiers: cmd,
        keyCode: 0x1D,
        position: 2,
        platform: 'windows',
        app: 'global',
      ),
      ShortcutKey(
        id: 'win_global_redo',
        name: '重做',
        icon: '🔄',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x1D,
        position: 3,
        platform: 'windows',
        app: 'global',
      ),
      ShortcutKey(
        id: 'win_global_cut',
        name: '剪切',
        icon: '✂️',
        modifiers: cmd,
        keyCode: 0x1B,
        position: 4,
        platform: 'windows',
        app: 'global',
      ),
      ShortcutKey(
        id: 'win_global_selectall',
        name: '全选',
        icon: '☑️',
        modifiers: cmd,
        keyCode: 0x04,
        position: 5,
        platform: 'windows',
        app: 'global',
      ),
      ShortcutKey(
        id: 'win_global_find',
        name: '查找',
        icon: '🔍',
        modifiers: cmd,
        keyCode: 0x09,
        position: 6,
        platform: 'windows',
        app: 'global',
      ),
      ShortcutKey(
        id: 'win_global_desktop',
        name: '显示桌面',
        icon: '🖥️',
        modifiers: HidModifiers.leftGui,
        keyCode: 0x07,
        position: 7,
        platform: 'windows',
        app: 'global',
      ),
      // 修正: Win+L 锁定，L = 0x0F
      ShortcutKey(
        id: 'win_global_lock',
        name: '锁定',
        icon: '🔒',
        modifiers: HidModifiers.leftGui,
        keyCode: 0x0F,
        position: 8,
        platform: 'windows',
        app: 'global',
      ),
      ShortcutKey(
        id: 'win_global_run',
        name: '运行',
        icon: '▶️',
        modifiers: HidModifiers.leftGui,
        keyCode: 0x15,
        position: 9,
        platform: 'windows',
        app: 'global',
      ),
      ShortcutKey(
        id: 'win_global_explorer',
        name: '资源管理器',
        icon: '📁',
        modifiers: HidModifiers.leftGui,
        keyCode: 0x08,
        position: 10,
        platform: 'windows',
        app: 'global',
      ),
    ];
  }

  static List<ShortcutKey> _getWindowsVscodeShortcuts() {
    const cmd = HidModifiers.leftCtrl;
    return [
      ShortcutKey(
        id: 'win_vscode_save',
        name: '保存',
        icon: '💾',
        modifiers: cmd,
        keyCode: 0x16,
        position: 0,
        platform: 'windows',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'win_vscode_saveall',
        name: '全部保存',
        icon: '💾',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x16,
        position: 1,
        platform: 'windows',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'win_vscode_find',
        name: '查找',
        icon: '🔍',
        modifiers: cmd,
        keyCode: 0x09,
        position: 2,
        platform: 'windows',
        app: 'vscode',
      ),
      // 修正: Ctrl+H 替换，H = 0x0B
      ShortcutKey(
        id: 'win_vscode_replace',
        name: '替换',
        icon: '🔁',
        modifiers: cmd,
        keyCode: 0x0B,
        position: 3,
        platform: 'windows',
        app: 'vscode',
      ),
      // 修正: Ctrl+G 跳转行，G = 0x0A
      ShortcutKey(
        id: 'win_vscode_goto',
        name: '跳转行',
        icon: '➡️',
        modifiers: cmd,
        keyCode: 0x0A,
        position: 4,
        platform: 'windows',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'win_vscode_terminal',
        name: '终端',
        icon: '💻',
        modifiers: cmd,
        keyCode: 0x35,
        position: 5,
        platform: 'windows',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'win_vscode_comment',
        name: '注释',
        icon: '💬',
        modifiers: cmd,
        keyCode: 0x38,
        position: 6,
        platform: 'windows',
        app: 'vscode',
      ),
      // 修正: Shift+Alt+F 格式化文档，修饰键改为 leftShift|leftAlt，F = 0x09
      ShortcutKey(
        id: 'win_vscode_format',
        name: '格式化',
        icon: '📝',
        modifiers: HidModifiers.leftShift | HidModifiers.leftAlt,
        keyCode: 0x09,
        position: 7,
        platform: 'windows',
        app: 'vscode',
      ),
      // 修正: Ctrl+W 关闭编辑器，W = 0x1A
      ShortcutKey(
        id: 'win_vscode_close',
        name: '关闭编辑器',
        icon: '❌',
        modifiers: cmd,
        keyCode: 0x1A,
        position: 8,
        platform: 'windows',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'win_vscode_newfile',
        name: '新建文件',
        icon: '📄',
        modifiers: cmd,
        keyCode: 0x11,
        position: 9,
        platform: 'windows',
        app: 'vscode',
      ),
      // 修正: Ctrl+Alt+↓ 多光标，↓ = 0x51
      ShortcutKey(
        id: 'win_vscode_multicursor',
        name: '多光标',
        icon: '🔀',
        modifiers: cmd | HidModifiers.leftAlt,
        keyCode: 0x51,
        position: 10,
        platform: 'windows',
        app: 'vscode',
      ),
    ];
  }

  static List<ShortcutKey> _getWindowsPhotoshopShortcuts() {
    const cmd = HidModifiers.leftCtrl;
    return [
      ShortcutKey(
        id: 'win_ps_save',
        name: '保存',
        icon: '💾',
        modifiers: cmd,
        keyCode: 0x16,
        position: 0,
        platform: 'windows',
        app: 'photoshop',
      ),
      ShortcutKey(
        id: 'win_ps_undo',
        name: '撤销',
        icon: '↩️',
        modifiers: cmd,
        keyCode: 0x1D,
        position: 1,
        platform: 'windows',
        app: 'photoshop',
      ),
      ShortcutKey(
        id: 'win_ps_redo',
        name: '重做',
        icon: '🔄',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x1D,
        position: 2,
        platform: 'windows',
        app: 'photoshop',
      ),
      // 修正: Ctrl+D 取消选择，D = 0x07
      ShortcutKey(
        id: 'win_ps_deselect',
        name: '取消选择',
        icon: '⬜',
        modifiers: cmd,
        keyCode: 0x07,
        position: 3,
        platform: 'windows',
        app: 'photoshop',
      ),
      // 修正: Ctrl+T 自由变换，T = 0x17
      ShortcutKey(
        id: 'win_ps_transform',
        name: '自由变换',
        icon: '🔲',
        modifiers: cmd,
        keyCode: 0x17,
        position: 4,
        platform: 'windows',
        app: 'photoshop',
      ),
      // 修正: Ctrl+Shift+I 反选，I = 0x0C
      ShortcutKey(
        id: 'win_ps_inverse',
        name: '反选',
        icon: '🔄',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x0C,
        position: 5,
        platform: 'windows',
        app: 'photoshop',
      ),
      // 修正: Ctrl+L 色阶，L = 0x0F
      ShortcutKey(
        id: 'win_ps_levels',
        name: '色阶',
        icon: '📊',
        modifiers: cmd,
        keyCode: 0x0F,
        position: 6,
        platform: 'windows',
        app: 'photoshop',
      ),
      // 修正: Ctrl+M 曲线，M = 0x10
      ShortcutKey(
        id: 'win_ps_curves',
        name: '曲线',
        icon: '📈',
        modifiers: cmd,
        keyCode: 0x10,
        position: 7,
        platform: 'windows',
        app: 'photoshop',
      ),
      // 修正: Ctrl+Shift+U 去色，U = 0x18
      ShortcutKey(
        id: 'win_ps_desaturate',
        name: '去色',
        icon: '🎨',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x18,
        position: 8,
        platform: 'windows',
        app: 'photoshop',
      ),
    ];
  }

  static List<ShortcutKey> _getWindowsBrowserShortcuts() {
    const cmd = HidModifiers.leftCtrl;
    return [
      ShortcutKey(
        id: 'win_browser_refresh',
        name: '刷新',
        icon: '🔄',
        modifiers: cmd,
        keyCode: 0x15,
        position: 0,
        platform: 'windows',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'win_browser_forceRefresh',
        name: '强制刷新',
        icon: '🔄',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x15,
        position: 1,
        platform: 'windows',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'win_browser_newTab',
        name: '新标签页',
        icon: '➕',
        modifiers: cmd,
        keyCode: 0x17,
        position: 2,
        platform: 'windows',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'win_browser_closeTab',
        name: '关闭标签',
        icon: '❌',
        modifiers: cmd,
        keyCode: 0x1A,
        position: 3,
        platform: 'windows',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'win_browser_reopenTab',
        name: '恢复标签',
        icon: '↩️',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x17,
        position: 4,
        platform: 'windows',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'win_browser_devTools',
        name: '开发者工具',
        icon: '🛠️',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x0C,
        position: 5,
        platform: 'windows',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'win_browser_find',
        name: '页面查找',
        icon: '🔍',
        modifiers: cmd,
        keyCode: 0x09,
        position: 6,
        platform: 'windows',
        app: 'browser',
      ),
      // 修正: Ctrl+H 历史记录，H = 0x0B
      ShortcutKey(
        id: 'win_browser_history',
        name: '历史记录',
        icon: '📜',
        modifiers: cmd,
        keyCode: 0x0B,
        position: 7,
        platform: 'windows',
        app: 'browser',
      ),
      // 修正: Ctrl+J 下载，J = 0x0D
      ShortcutKey(
        id: 'win_browser_downloads',
        name: '下载',
        icon: '📥',
        modifiers: cmd,
        keyCode: 0x0D,
        position: 8,
        platform: 'windows',
        app: 'browser',
      ),
    ];
  }

  // ==================== macOS 快捷键 ====================

  static List<ShortcutKey> _getMacosGlobalShortcuts() {
    const cmd = HidModifiers.leftGui;
    return [
      ShortcutKey(
        id: 'mac_global_copy',
        name: '复制',
        icon: '📋',
        modifiers: cmd,
        keyCode: 0x06,
        position: 0,
        platform: 'macos',
        app: 'global',
      ),
      ShortcutKey(
        id: 'mac_global_paste',
        name: '粘贴',
        icon: '📄',
        modifiers: cmd,
        keyCode: 0x19,
        position: 1,
        platform: 'macos',
        app: 'global',
      ),
      ShortcutKey(
        id: 'mac_global_undo',
        name: '撤销',
        icon: '↩️',
        modifiers: cmd,
        keyCode: 0x1D,
        position: 2,
        platform: 'macos',
        app: 'global',
      ),
      ShortcutKey(
        id: 'mac_global_redo',
        name: '重做',
        icon: '🔄',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x1D,
        position: 3,
        platform: 'macos',
        app: 'global',
      ),
      ShortcutKey(
        id: 'mac_global_cut',
        name: '剪切',
        icon: '✂️',
        modifiers: cmd,
        keyCode: 0x1B,
        position: 4,
        platform: 'macos',
        app: 'global',
      ),
      ShortcutKey(
        id: 'mac_global_selectall',
        name: '全选',
        icon: '☑️',
        modifiers: cmd,
        keyCode: 0x04,
        position: 5,
        platform: 'macos',
        app: 'global',
      ),
      ShortcutKey(
        id: 'mac_global_find',
        name: '查找',
        icon: '🔍',
        modifiers: cmd,
        keyCode: 0x09,
        position: 6,
        platform: 'macos',
        app: 'global',
      ),
      ShortcutKey(
        id: 'mac_global_desktop',
        name: '显示桌面',
        icon: '🖥️',
        modifiers: cmd,
        keyCode: 0x07,
        position: 7,
        platform: 'macos',
        app: 'global',
      ),
      ShortcutKey(
        id: 'mac_global_lock',
        name: '锁屏',
        icon: '🔒',
        modifiers: cmd | HidModifiers.leftCtrl,
        keyCode: 0x14,
        position: 8,
        platform: 'macos',
        app: 'global',
      ),
      ShortcutKey(
        id: 'mac_global_spotlight',
        name: 'Spotlight',
        icon: '🔍',
        modifiers: cmd,
        keyCode: 0x2C,
        position: 9,
        platform: 'macos',
        app: 'global',
      ),
      // 修正: Cmd+Shift+H 前往个人主页（Finder），H = 0x0B
      ShortcutKey(
        id: 'mac_global_finder',
        name: 'Finder',
        icon: '📁',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x0B,
        position: 10,
        platform: 'macos',
        app: 'global',
      ),
    ];
  }

  static List<ShortcutKey> _getMacosVscodeShortcuts() {
    const cmd = HidModifiers.leftGui;
    return [
      ShortcutKey(
        id: 'mac_vscode_save',
        name: '保存',
        icon: '💾',
        modifiers: cmd,
        keyCode: 0x16,
        position: 0,
        platform: 'macos',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'mac_vscode_saveall',
        name: '全部保存',
        icon: '💾',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x16,
        position: 1,
        platform: 'macos',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'mac_vscode_find',
        name: '查找',
        icon: '🔍',
        modifiers: cmd,
        keyCode: 0x09,
        position: 2,
        platform: 'macos',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'mac_vscode_replace',
        name: '替换',
        icon: '🔁',
        modifiers: cmd | HidModifiers.leftAlt,
        keyCode: 0x09,
        position: 3,
        platform: 'macos',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'mac_vscode_goto',
        name: '跳转行',
        icon: '➡️',
        modifiers: cmd,
        keyCode: 0x0B,
        position: 4,
        platform: 'macos',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'mac_vscode_terminal',
        name: '终端',
        icon: '💻',
        modifiers: cmd,
        keyCode: 0x35,
        position: 5,
        platform: 'macos',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'mac_vscode_comment',
        name: '注释',
        icon: '💬',
        modifiers: cmd,
        keyCode: 0x38,
        position: 6,
        platform: 'macos',
        app: 'vscode',
      ),
      // 修正: Shift+Alt+F 格式化文档，修饰键改为 leftShift|leftAlt，F = 0x09
      ShortcutKey(
        id: 'mac_vscode_format',
        name: '格式化',
        icon: '📝',
        modifiers: HidModifiers.leftShift | HidModifiers.leftAlt,
        keyCode: 0x09,
        position: 7,
        platform: 'macos',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'mac_vscode_close',
        name: '关闭编辑器',
        icon: '❌',
        modifiers: cmd,
        keyCode: 0x1A,
        position: 8,
        platform: 'macos',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'mac_vscode_newfile',
        name: '新建文件',
        icon: '📄',
        modifiers: cmd,
        keyCode: 0x11,
        position: 9,
        platform: 'macos',
        app: 'vscode',
      ),
      ShortcutKey(
        id: 'mac_vscode_multicursor',
        name: '多光标',
        icon: '🔀',
        modifiers: cmd | HidModifiers.leftAlt,
        keyCode: 0x51,
        position: 10,
        platform: 'macos',
        app: 'vscode',
      ),
      // 修正: Cmd+Shift+P 命令面板，P = 0x13
      ShortcutKey(
        id: 'mac_vscode_command',
        name: '命令面板',
        icon: '⌨️',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x13,
        position: 11,
        platform: 'macos',
        app: 'vscode',
      ),
    ];
  }

  static List<ShortcutKey> _getMacosPhotoshopShortcuts() {
    const cmd = HidModifiers.leftGui;
    return [
      ShortcutKey(
        id: 'mac_ps_save',
        name: '保存',
        icon: '💾',
        modifiers: cmd,
        keyCode: 0x16,
        position: 0,
        platform: 'macos',
        app: 'photoshop',
      ),
      ShortcutKey(
        id: 'mac_ps_undo',
        name: '撤销',
        icon: '↩️',
        modifiers: cmd,
        keyCode: 0x1D,
        position: 1,
        platform: 'macos',
        app: 'photoshop',
      ),
      ShortcutKey(
        id: 'mac_ps_redo',
        name: '重做',
        icon: '🔄',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x1D,
        position: 2,
        platform: 'macos',
        app: 'photoshop',
      ),
      // 修正: Cmd+D 取消选择，D = 0x07
      ShortcutKey(
        id: 'mac_ps_deselect',
        name: '取消选择',
        icon: '⬜',
        modifiers: cmd,
        keyCode: 0x07,
        position: 3,
        platform: 'macos',
        app: 'photoshop',
      ),
      // 修正: Cmd+T 自由变换，T = 0x17
      ShortcutKey(
        id: 'mac_ps_transform',
        name: '自由变换',
        icon: '🔲',
        modifiers: cmd,
        keyCode: 0x17,
        position: 4,
        platform: 'macos',
        app: 'photoshop',
      ),
      // 修正: Cmd+Shift+I 反选，I = 0x0C
      ShortcutKey(
        id: 'mac_ps_inverse',
        name: '反选',
        icon: '🔄',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x0C,
        position: 5,
        platform: 'macos',
        app: 'photoshop',
      ),
      // 修正: Cmd+L 色阶，L = 0x0F
      ShortcutKey(
        id: 'mac_ps_levels',
        name: '色阶',
        icon: '📊',
        modifiers: cmd,
        keyCode: 0x0F,
        position: 6,
        platform: 'macos',
        app: 'photoshop',
      ),
      // 修正: Cmd+M 曲线，M = 0x10
      ShortcutKey(
        id: 'mac_ps_curves',
        name: '曲线',
        icon: '📈',
        modifiers: cmd,
        keyCode: 0x10,
        position: 7,
        platform: 'macos',
        app: 'photoshop',
      ),
      // 修正: Cmd+Shift+U 去色，U = 0x18
      ShortcutKey(
        id: 'mac_ps_desaturate',
        name: '去色',
        icon: '🎨',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x18,
        position: 8,
        platform: 'macos',
        app: 'photoshop',
      ),
    ];
  }

  static List<ShortcutKey> _getMacosBrowserShortcuts() {
    const cmd = HidModifiers.leftGui;
    return [
      ShortcutKey(
        id: 'mac_browser_refresh',
        name: '刷新',
        icon: '🔄',
        modifiers: cmd,
        keyCode: 0x15,
        position: 0,
        platform: 'macos',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'mac_browser_forceRefresh',
        name: '强制刷新',
        icon: '🔄',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x15,
        position: 1,
        platform: 'macos',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'mac_browser_newTab',
        name: '新标签页',
        icon: '➕',
        modifiers: cmd,
        keyCode: 0x17,
        position: 2,
        platform: 'macos',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'mac_browser_closeTab',
        name: '关闭标签',
        icon: '❌',
        modifiers: cmd,
        keyCode: 0x1A,
        position: 3,
        platform: 'macos',
        app: 'browser',
      ),
      // 修正: Cmd+Shift+T 恢复标签，T = 0x17
      ShortcutKey(
        id: 'mac_browser_reopenTab',
        name: '恢复标签',
        icon: '↩️',
        modifiers: cmd | HidModifiers.leftShift,
        keyCode: 0x17,
        position: 4,
        platform: 'macos',
        app: 'browser',
      ),
      // 修正: Cmd+Option+I 开发者工具，I = 0x0C
      ShortcutKey(
        id: 'mac_browser_devTools',
        name: '开发者工具',
        icon: '🛠️',
        modifiers: cmd | HidModifiers.leftAlt,
        keyCode: 0x0C,
        position: 5,
        platform: 'macos',
        app: 'browser',
      ),
      ShortcutKey(
        id: 'mac_browser_find',
        name: '页面查找',
        icon: '🔍',
        modifiers: cmd,
        keyCode: 0x09,
        position: 6,
        platform: 'macos',
        app: 'browser',
      ),
      // 修正: Cmd+Y 历史记录（Chrome macOS），Y = 0x1C
      ShortcutKey(
        id: 'mac_browser_history',
        name: '历史记录',
        icon: '📜',
        modifiers: cmd,
        keyCode: 0x1C,
        position: 7,
        platform: 'macos',
        app: 'browser',
      ),
      // 修正: Cmd+Option+L 下载（Chrome macOS），L = 0x0F
      ShortcutKey(
        id: 'mac_browser_downloads',
        name: '下载',
        icon: '📥',
        modifiers: cmd | HidModifiers.leftAlt,
        keyCode: 0x0F,
        position: 8,
        platform: 'macos',
        app: 'browser',
      ),
    ];
  }

  @override
  String toString() {
    return 'ShortcutKey(id: $id, name: $name, platform: $platform, app: $app)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShortcutKey && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
