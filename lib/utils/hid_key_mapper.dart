/// HID 键码映射器
/// 对应 Android: HidKeyMapper.kt
/// 负责将字符转换为 HID 键码和修饰键
///
/// 这个类处理键盘输入的字符到 HID 报告格式的转换
/// 包括大小写、特殊符号的处理

class HidKeyInfo {
  /// HID 键码
  final int keyCode;

  /// 修饰键位掩码 (Shift, Ctrl, Alt 等)
  final int modifiers;

  const HidKeyInfo(this.keyCode, this.modifiers);

  @override
  String toString() => 'HidKeyInfo(keyCode: 0x${keyCode.toRadixString(16).padLeft(2, '0').toUpperCase()}, modifiers: $modifiers)';
}

class HidKeyMapper {
  HidKeyMapper._();

  /// 将字符转换为 HID 键码信息
  /// 对应 Android: HidKeyMapper.charToHid(c)
  ///
  /// 处理逻辑：
  /// 1. 小写字母：直接映射到 A-Z 键码
  /// 2. 大写字母：映射到 A-Z 键码 + Shift 修饰键
  /// 3. 数字：直接映射
  /// 4. 符号：根据键盘布局映射，可能需要 Shift
  /// 5. 特殊字符（回车、退格等）：映射到对应的控制键
  static HidKeyInfo? charToHid(String char) {
    if (char.isEmpty) return null;

    final c = char[0];

    final code = c.codeUnitAt(0);

    // 处理小写字母 a-z (a=97, z=122)
    if (code >= 97 && code <= 122) {
      return HidKeyInfo(_letterToHid(c), 0);
    }

    // 处理大写字母 A-Z (A=65, Z=90)
    if (code >= 65 && code <= 90) {
      return HidKeyInfo(_letterToHid(c.toLowerCase()), 0x02); // 0x02 = Left Shift
    }

    // 处理数字 0-9 (0=48, 9=57)
    if (code >= 48 && code <= 57) {
      return HidKeyInfo(_digitToHid(c), 0);
    }

    // 处理特殊字符和符号
    return _symbolToHid(c);
  }

  /// 将字符串逐字符转换为 HID 键码序列
  /// 用于实现 "输入字符串" 功能
  static List<HidKeyInfo> stringToHid(String text) {
    final result = <HidKeyInfo>[];
    for (final char in text.split('')) {
      final info = charToHid(char);
      if (info != null) {
        result.add(info);
      }
    }
    return result;
  }

  // ==================== 私有映射方法 ====================

  /// 字母 a-z 到 HID 键码的映射
  /// HID 键码: A=0x04, B=0x05, ... Z=0x1D
  static int _letterToHid(String letter) {
    final code = letter.codeUnitAt(0);
    // 'a' = 97, HID 'a' = 0x04
    return code - 97 + 0x04;
  }

  /// 数字 0-9 到 HID 键码的映射
  /// HID 键码: 1=0x1E, 2=0x1F, ... 0=0x27
  static int _digitToHid(String digit) {
    if (digit == '0') return 0x27;
    final code = digit.codeUnitAt(0);
    // '1' = 49, HID '1' = 0x1E
    return code - 49 + 0x1E;
  }

  /// 符号到 HID 键码的映射
  /// 需要考虑是否需要 Shift 键
  static HidKeyInfo? _symbolToHid(String symbol) {
    const symbolMap = <String, HidKeyInfo>{
      // 空格
      ' ': HidKeyInfo(0x2C, 0), // Space

      // 回车和换行
      '\n': HidKeyInfo(0x28, 0), // Enter
      '\r': HidKeyInfo(0x28, 0), // Enter

      // 退格
      '\b': HidKeyInfo(0x2A, 0), // Backspace

      // Tab
      '\t': HidKeyInfo(0x2B, 0), // Tab

      // 无 Shift 的符号
      '-': HidKeyInfo(0x2D, 0),
      '=': HidKeyInfo(0x2E, 0),
      '[': HidKeyInfo(0x2F, 0),
      ']': HidKeyInfo(0x30, 0),
      '\\': HidKeyInfo(0x31, 0),
      ';': HidKeyInfo(0x33, 0),
      "'": HidKeyInfo(0x34, 0),
      '`': HidKeyInfo(0x35, 0),
      ',': HidKeyInfo(0x36, 0),
      '.': HidKeyInfo(0x37, 0),
      '/': HidKeyInfo(0x38, 0),

      // 需要 Shift 的符号
      '_': HidKeyInfo(0x2D, 0x02), // Shift + -
      '+': HidKeyInfo(0x2E, 0x02), // Shift + =
      '{': HidKeyInfo(0x2F, 0x02), // Shift + [
      '}': HidKeyInfo(0x30, 0x02), // Shift + ]
      '|': HidKeyInfo(0x31, 0x02), // Shift + \
      ':': HidKeyInfo(0x33, 0x02), // Shift + ;
      '"': HidKeyInfo(0x34, 0x02), // Shift + '
      '~': HidKeyInfo(0x35, 0x02), // Shift + `
      '<': HidKeyInfo(0x36, 0x02), // Shift + ,
      '>': HidKeyInfo(0x37, 0x02), // Shift + .
      '?': HidKeyInfo(0x38, 0x02), // Shift + /
      '!': HidKeyInfo(0x1E, 0x02), // Shift + 1
      '@': HidKeyInfo(0x1F, 0x02), // Shift + 2
      '#': HidKeyInfo(0x20, 0x02), // Shift + 3
      r'$': HidKeyInfo(0x21, 0x02), // Shift + 4
      '%': HidKeyInfo(0x22, 0x02), // Shift + 5
      '^': HidKeyInfo(0x23, 0x02), // Shift + 6
      '&': HidKeyInfo(0x24, 0x02), // Shift + 7
      '*': HidKeyInfo(0x25, 0x02), // Shift + 8
      '(': HidKeyInfo(0x26, 0x02), // Shift + 9
      ')': HidKeyInfo(0x27, 0x02), // Shift + 0
    };

    return symbolMap[symbol];
  }

  /// 检查字符是否可以直接通过 HID 输入
  static bool canType(String char) {
    return charToHid(char) != null;
  }

  /// 过滤字符串，只保留可以输入的字符
  static String filterTypeable(String text) {
    return text.split('').where(canType).join();
  }
}
