/// HID 报告构建器
/// 对应 Android: HidReportBuilder.kt
/// 负责构建 USB HID 报告数据包
///
/// HID (Human Interface Device) 报告格式参考：
/// - USB HID Usage Tables: https://usb.org/sites/default/files/hut1_21.pdf
/// - 鼠标报告: 4字节 [buttons, x, y, wheel]
/// - 键盘报告: 8字节 [modifiers, reserved, key1, key2, key3, key4, key5, key6]
/// - 多媒体报告: 2字节 [consumer key]

class HidReportBuilder {
  // 私有构造函数，防止实例化
  HidReportBuilder._();

  // ==================== 报告 ID ====================
  /// 鼠标报告 ID
  static const int idMouse = 1;

  /// 键盘报告 ID
  static const int idKeyboard = 2;

  /// 多媒体/消费者控制报告 ID
  static const int idConsumer = 3;

  // ==================== 修饰键常量 ====================
  /// 左 Ctrl
  static const int modLCtrl = 0x01;

  /// 左 Shift
  static const int modLShift = 0x02;

  /// 左 Alt
  static const int modLAlt = 0x04;

  /// 左 GUI (Windows/Cmd 键)
  static const int modLGui = 0x08;

  /// 右 Ctrl
  static const int modRCtrl = 0x10;

  /// 右 Shift
  static const int modRShift = 0x20;

  /// 右 Alt
  static const int modRAlt = 0x40;

  /// 右 GUI
  static const int modRGui = 0x80;

  // ==================== 多媒体键常量 ====================
  /// 播放/暂停
  static const int consumerPlayPause = 0x01;

  /// 下一曲
  static const int consumerNextTrack = 0x02;

  /// 上一曲
  static const int consumerPrevTrack = 0x04;

  /// 停止
  static const int consumerStop = 0x08;

  /// 静音
  static const int consumerMute = 0x10;

  /// 音量加
  static const int consumerVolumeUp = 0x20;

  /// 音量减
  static const int consumerVolumeDown = 0x40;

  // ==================== 鼠标报告 ====================

  /// 构建鼠标报告
  /// [dx] X轴移动量 (-127 ~ 127)
  /// [dy] Y轴移动量 (-127 ~ 127)
  /// [buttons] 按钮状态位掩码 (bit0=左键, bit1=右键, bit2=中键)
  /// [wheel] 滚轮滚动量 (-127 ~ 127)
  /// 返回: 4字节列表 [buttons, dx, dy, wheel]
  static List<int> buildMouseReport(
    int dx,
    int dy, {
    int buttons = 0,
    int wheel = 0,
  }) {
    // 限制数值范围到 -127 ~ 127
    final clampedDx = dx.clamp(-127, 127);
    final clampedDy = dy.clamp(-127, 127);
    final clampedWheel = wheel.clamp(-127, 127);

    // 将有符号数转换为无符号字节 (Dart 的 int 是带符号的，但 HID 报告需要字节)
    return [
      buttons & 0xFF,
      _toUnsignedByte(clampedDx),
      _toUnsignedByte(clampedDy),
      _toUnsignedByte(clampedWheel),
    ];
  }

  // ==================== 键盘报告 ====================

  /// 构建键盘报告
  /// [modifiers] 修饰键位掩码 (组合使用 modLCtrl, modLShift 等)
  /// [keyCodes] 按键码列表 (最多6个键同时按下)
  /// 返回: 8字节列表 [modifiers, reserved, key1, key2, key3, key4, key5, key6]
  static List<int> buildKeyboardReport(
    int modifiers,
    List<int> keyCodes,
  ) {
    // 限制最多6个按键
    final keys = keyCodes.take(6).toList();

    // 填充到6个按键
    while (keys.length < 6) {
      keys.add(0);
    }

    return [
      modifiers & 0xFF,
      0, // reserved
      keys[0] & 0xFF,
      keys[1] & 0xFF,
      keys[2] & 0xFF,
      keys[3] & 0xFF,
      keys[4] & 0xFF,
      keys[5] & 0xFF,
    ];
  }

  // ==================== 多媒体报告 ====================

  /// 构建消费者控制报告 (多媒体键)
  /// [mask] 多媒体键位掩码 (组合使用 consumerPlayPause, consumerVolumeUp 等)
  /// 返回: 2字节列表
  static List<int> buildConsumerReport(int mask) {
    return [
      mask & 0xFF,
      (mask >> 8) & 0xFF,
    ];
  }

  // ==================== 按键码映射 ====================

  /// 根据键名字符串获取 HID 键码
  /// 对应 Android: HidReportBuilder.getKeyCode()
  static int getKeyCode(String keyName) {
    final key = keyName.toUpperCase();
    return _keyCodeMap[key] ?? 0;
  }

  /// 按键名到 HID 键码的映射表
  /// 参考 USB HID Usage Tables (Keyboard/Keypad Page 0x07)
  static const Map<String, int> _keyCodeMap = {
    // 字母 A-Z
    'A': 0x04, 'B': 0x05, 'C': 0x06, 'D': 0x07, 'E': 0x08,
    'F': 0x09, 'G': 0x0A, 'H': 0x0B, 'I': 0x0C, 'J': 0x0D,
    'K': 0x0E, 'L': 0x0F, 'M': 0x10, 'N': 0x11, 'O': 0x12,
    'P': 0x13, 'Q': 0x14, 'R': 0x15, 'S': 0x16, 'T': 0x17,
    'U': 0x18, 'V': 0x19, 'W': 0x1A, 'X': 0x1B, 'Y': 0x1C,
    'Z': 0x1D,

    // 数字 1-0
    '1': 0x1E, '2': 0x1F, '3': 0x20, '4': 0x21, '5': 0x22,
    '6': 0x23, '7': 0x24, '8': 0x25, '9': 0x26, '0': 0x27,

    // 功能键
    'ENTER': 0x28, 'ESC': 0x29, 'BACKSPACE': 0x2A, 'TAB': 0x2B,
    'SPACE': 0x2C, ' ': 0x2C,

    // 符号
    '-': 0x2D, '=': 0x2E, '[': 0x2F, ']': 0x30, '\\': 0x31,
    ';': 0x33, "'": 0x34, '`': 0x35, ',': 0x36, '.': 0x37,
    '/': 0x38,

    // 功能键 F1-F12
    'F1': 0x3A, 'F2': 0x3B, 'F3': 0x3C, 'F4': 0x3D,
    'F5': 0x3E, 'F6': 0x3F, 'F7': 0x40, 'F8': 0x41,
    'F9': 0x42, 'F10': 0x43, 'F11': 0x44, 'F12': 0x45,

    // 控制键
    'PRTSC': 0x46, 'SCROLL': 0x47, 'PAUSE': 0x48,
    'INSERT': 0x49, 'HOME': 0x4A, 'PGUP': 0x4B,
    'DELETE': 0x4C, 'END': 0x4D, 'PGDN': 0x4E,
    'RIGHT': 0x4F, 'LEFT': 0x50, 'DOWN': 0x51, 'UP': 0x52,

    // 小键盘
    'NUMLOCK': 0x53, 'KP/': 0x54, 'KP*': 0x55, 'KP-': 0x56,
    'KP+': 0x57, 'KPENTER': 0x58, 'KP1': 0x59, 'KP2': 0x5A,
    'KP3': 0x5B, 'KP4': 0x5C, 'KP5': 0x5D, 'KP6': 0x5E,
    'KP7': 0x5F, 'KP8': 0x60, 'KP9': 0x61, 'KP0': 0x62,
    'KP.': 0x63,
  };

  // ==================== 辅助方法 ====================

  /// 将有符号整数转换为无符号字节 (0-255)
  static int _toUnsignedByte(int value) {
    if (value < 0) {
      return value + 256;
    }
    return value & 0xFF;
  }

  /// 构建鼠标按钮位掩码
  /// [left] 左键
  /// [right] 右键
  /// [middle] 中键
  static int buildMouseButtons({
    bool left = false,
    bool right = false,
    bool middle = false,
  }) {
    int buttons = 0;
    if (left) buttons |= 0x01;
    if (right) buttons |= 0x02;
    if (middle) buttons |= 0x04;
    return buttons;
  }
}
