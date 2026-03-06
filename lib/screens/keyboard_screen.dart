import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/touchpad_area.dart';
import '../widgets/connection_bar.dart';
import '../models/models.dart';
import '../utils/l10n_utils.dart';
import '../utils/hid_key_mapper.dart';

/// 键盘屏幕
/// 对应 Android: KeyboardScreen.kt
class KeyboardScreen extends ConsumerStatefulWidget {
  const KeyboardScreen({super.key});

  @override
  ConsumerState<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends ConsumerState<KeyboardScreen> {
  int _mode = 0; // 0: ABC, 1: 123, 2: Sym, 3: Fn, 4: Nav
  bool _isCapsLock = false;
  int _activeModifiers = 0;
  bool _isModifierLocked = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final actions = ref.read(bluetoothActionsProvider);

    // 使用 settings.osType 替代设备名称判断
    final isMac = settings.osType == "macOS";

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          // --- Touchpad Area (larger) ---
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? DarkColors.border : LightColors.border,
                      width: 1.5,
                    ),
                  ),
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
                      _sendMouseClick(actions, button);
                    },
                    onScroll: (v, h) {
                      actions.sendScroll(v, horizontal: h);
                    },
                    onZoomStart: () => actions.sendZoom(0, isStart: true),
                    onZoomUpdate: (delta) => actions.sendZoom(delta),
                    onZoomEnd: () => actions.sendZoom(0, isEnd: true),
                    onThreeFingerTap: () => actions.sendThreeFingerTap(),
                    onThreeFingerSwipe: (direction) {
                      // 简单映射方向手势
                      int mods = 0x08; // Win/Cmd
                      int key = 0;
                      if (direction == SwipeDirection.up) key = 0x52;
                      if (direction == SwipeDirection.down) key = 0x51;
                      if (direction == SwipeDirection.left) key = 0x50;
                      if (direction == SwipeDirection.right) key = 0x4F;
                      actions.sendKeyPress(mods, [key]);
                    },
                  ),
                ),
              ),
            ),
          ),

          // --- Control Row ---
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _ModeBtn(label: context.s('kb_mode_abc'), isActive: _mode == 0, onTap: () => setState(() => _mode = 0)),
                    const SizedBox(width: 4),
                    _ModeBtn(label: context.s('kb_mode_123'), isActive: _mode == 1, onTap: () => setState(() => _mode = 1)),
                    const SizedBox(width: 4),
                    _ModeBtn(label: context.s('kb_mode_sym'), isActive: _mode == 2, onTap: () => setState(() => _mode = 2)),
                    const SizedBox(width: 4),
                    _ModeBtn(label: context.s('kb_mode_fn'), isActive: _mode == 3, onTap: () => setState(() => _mode = 3)),
                    const SizedBox(width: 4),
                    _ModeBtn(label: context.s('kb_mode_nav'), isActive: _mode == 4, onTap: () => setState(() => _mode = 4)),
                    const SizedBox(width: 4),
                    _ModifierLockBtn(
                      isLocked: _isModifierLocked,
                      onTap: () => setState(() => _isModifierLocked = !_isModifierLocked),
                    ),
                  ],
                ),
                _ModeBtn(
                  label: '中/EN',
                  isActive: false,
                  onTap: () {
                    // 切换输入法: 发送 Ctrl+Space
                    actions.sendKeyPress(0x01, [0x2C]);
                  },
                ),
                const SizedBox(width: 4),
                // OS 切换按钮
                _OsToggleBtn(
                  isMac: isMac,
                  onTap: () => settingsNotifier.setOsType(isMac ? "Windows" : "macOS"),
                ),
              ],
            ),
          ),

          // --- Modifiers Row ---
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: _buildModifiers(isMac),
            ),
          ),

          // --- Keyboard Layout (at bottom, smaller) ---
          Expanded(
            flex: 3,
            child: _buildLayout(actions, isMac, settings.haptic ? () => actions.vibrate(10) : null),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildModifiers(bool isMac) {
    if (isMac) {
      return [
        _ModifierKey(label: '⌃ Control', mask: 0x01, activeMask: _activeModifiers, isLocked: _isModifierLocked, onTap: _toggleModifier),
        const SizedBox(width: 4),
        _ModifierKey(label: '⌥ Option', mask: 0x04, activeMask: _activeModifiers, isLocked: _isModifierLocked, onTap: _toggleModifier),
        _ModifierKey(label: '⌘ Command', mask: 0x08, activeMask: _activeModifiers, isLocked: _isModifierLocked, flex: 1.2, onTap: _toggleModifier),
        const SizedBox(width: 4),
        _ModifierKey(label: '⇧ Shift', mask: 0x02, activeMask: _activeModifiers, isLocked: _isModifierLocked, onTap: _toggleModifier),
      ];
    } else {
      return [
        _ModifierKey(label: 'Ctrl', mask: 0x01, activeMask: _activeModifiers, isLocked: _isModifierLocked, onTap: _toggleModifier),
        const SizedBox(width: 4),
        _ModifierKey(label: 'Win', mask: 0x08, activeMask: _activeModifiers, isLocked: _isModifierLocked, onTap: _toggleModifier),
        const SizedBox(width: 4),
        _ModifierKey(label: 'Alt', mask: 0x04, activeMask: _activeModifiers, isLocked: _isModifierLocked, onTap: _toggleModifier),
        const SizedBox(width: 4),
        _ModifierKey(label: '⇧ Shift', mask: 0x02, activeMask: _activeModifiers, isLocked: _isModifierLocked, onTap: _toggleModifier),
      ];
    }
  }

  void _toggleModifier(int mask) {
    setState(() {
      if ((_activeModifiers & mask) != 0) {
        _activeModifiers &= ~mask;
      } else {
        _activeModifiers |= mask;
      }
    });
  }

  Widget _buildLayout(BluetoothActions actions, bool isMac, VoidCallback? onHaptic) {
    switch (_mode) {
      case 0:
        return _QWERTYLayout(
          actions: actions,
          isCapsLock: _isCapsLock,
          onCapsLock: () => setState(() => _isCapsLock = !_isCapsLock),
          modifiers: _activeModifiers,
          onKeyTap: () {
            if (!_isModifierLocked) setState(() => _activeModifiers = 0);
          },
          onHaptic: onHaptic,
        );
      case 1: return _NumberLayout(actions: actions, onHaptic: onHaptic);
      case 2: return _SymbolLayout(actions: actions, onHaptic: onHaptic);
      case 3: return _FnLayout(actions: actions, modifiers: _activeModifiers, onHaptic: onHaptic);
      case 4: return _NavLayout(actions: actions, modifiers: _activeModifiers, onHaptic: onHaptic);
      default: return Container();
    }
  }

  void _sendMouseClick(BluetoothActions actions, MouseButton button) {
    int mask = (button == MouseButton.left) ? 0x01 : (button == MouseButton.right ? 0x02 : 0x04);
    actions.sendMouseMove(0, 0, buttons: mask);
    Future.delayed(const Duration(milliseconds: 50), () => actions.sendMouseMove(0, 0, buttons: 0));
  }
}

// --- Components ---

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeBtn({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final surfaceVariant = isDark ? DarkColors.bg3 : LightColors.bg3;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? accentColor.withOpacity(0.1) : surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? accentColor : (isDark ? DarkColors.border : LightColors.border)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? accentColor : onSurfaceVariant, 
            fontSize: 10, 
            fontFamily: 'monospace',
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ModifierLockBtn extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onTap;

  const _ModifierLockBtn({required this.isLocked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isLocked ? accentColor : (isDark ? DarkColors.bg3 : LightColors.bg3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isLocked ? accentColor : (isDark ? DarkColors.border : LightColors.border)),
        ),
        child: Icon(
          Icons.push_pin,
          size: 14,
          color: isLocked ? Colors.white : (isDark ? DarkColors.text2.withOpacity(0.5) : LightColors.text2.withOpacity(0.5)),
        ),
      ),
    );
  }
}

class _OsToggleBtn extends StatelessWidget {
  final bool isMac;
  final VoidCallback onTap;

  const _OsToggleBtn({required this.isMac, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final bgColor = isDark ? DarkColors.bg3 : LightColors.bg3;
    final borderColor = isDark ? DarkColors.border : LightColors.border;
    final textColor = isDark ? DarkColors.text2 : LightColors.text2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMac ? Icons.apple : Icons.computer,
              size: 14,
              color: isMac ? accentColor : textColor,
            ),
            const SizedBox(width: 4),
            Text(
              isMac ? 'Mac' : 'Win',
              style: TextStyle(
                color: isMac ? accentColor : textColor,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModifierKey extends StatelessWidget {
  final String label;
  final int mask;
  final int activeMask;
  final bool isLocked;
  final double flex;
  final Function(int) onTap;

  const _ModifierKey({
    required this.label,
    required this.mask,
    required this.activeMask,
    required this.isLocked,
    this.flex = 1.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = (activeMask & mask) != 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;

    final effectivelyLocked = isActive && isLocked;
    final bgColor = effectivelyLocked 
      ? accentColor 
      : (isActive ? accentColor.withOpacity(0.2) : (isDark ? DarkColors.bg3 : LightColors.bg3));
    
    return Expanded(
      flex: (flex * 10).toInt(),
      child: GestureDetector(
        onTap: () => onTap(mask),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isActive ? accentColor : (isDark ? DarkColors.border : LightColors.border)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: effectivelyLocked ? Colors.white : (isActive ? accentColor : (isDark ? DarkColors.text2 : LightColors.text2)),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double flex;
  final bool isWide;
  final VoidCallback? onHaptic;

  const _Key({required this.label, required this.onTap, this.flex = 1.0, this.isWide = false, this.onHaptic});

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final surfaceColor = isDark ? DarkColors.bg2 : LightColors.bg2;
    final onSurface = isDark ? DarkColors.text : LightColors.text;

    return Expanded(
      flex: (widget.flex * 10).toInt(),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          widget.onHaptic?.call();
          widget.onTap();
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: _isPressed ? accentColor : surfaceColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _isPressed ? accentColor : (isDark ? DarkColors.border : LightColors.border)),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: _isPressed ? Colors.white : onSurface,
              fontSize: widget.isWide ? 10 : 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Layouts ---

class _QWERTYLayout extends StatelessWidget {
  final BluetoothActions actions;
  final bool isCapsLock;
  final VoidCallback onCapsLock;
  final int modifiers;
  final VoidCallback onKeyTap;
  final VoidCallback? onHaptic;

  const _QWERTYLayout({
    required this.actions,
    required this.isCapsLock,
    required this.onCapsLock,
    required this.modifiers,
    required this.onKeyTap,
    this.onHaptic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow("qwertyuiop".split("")),
        const SizedBox(height: 4),
        Row(
          children: [
            ..._buildRowList("asdfghjkl".split("")),
            const SizedBox(width: 4),
            _Key(label: '⌫', flex: 1.5, isWide: true, onHaptic: onHaptic, onTap: () {
              actions.sendKeyPress(modifiers, [0x2A]);
              onKeyTap();
            }),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _Key(label: 'Caps', flex: 1.5, isWide: true, onHaptic: onHaptic, onTap: onCapsLock),
            const SizedBox(width: 4),
            ..._buildRowList("zxcvbnm".split("")),
            const SizedBox(width: 4),
            _Key(label: '↵', flex: 1.5, isWide: true, onHaptic: onHaptic, onTap: () {
              actions.sendKeyPress(modifiers, [0x28]);
              onKeyTap();
            }),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _Key(label: 'Esc', flex: 1.2, isWide: true, onHaptic: onHaptic, onTap: () => actions.sendKeyPress(0, [0x29])),
            const SizedBox(width: 4),
            _Key(label: ',', onHaptic: onHaptic, onTap: () {
               actions.typeString(",");
               onKeyTap();
            }),
            const SizedBox(width: 4),
            _Key(label: 'Space', flex: 3.5, onHaptic: onHaptic, onTap: () {
               actions.sendKeyPress(modifiers, [0x2C]);
               onKeyTap();
            }),
            const SizedBox(width: 4),
            _Key(label: '.', onHaptic: onHaptic, onTap: () {
               actions.typeString(".");
               onKeyTap();
            }),
            const SizedBox(width: 4),
            _Key(label: '/', onHaptic: onHaptic, onTap: () {
               actions.typeString("/");
               onKeyTap();
            }),
            const SizedBox(width: 4),
            _Key(label: 'Tab', flex: 1.2, isWide: true, onHaptic: onHaptic, onTap: () {
               actions.sendKeyPress(modifiers, [0x2B]);
               onKeyTap();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> chars) {
    return Row(
      children: _buildRowList(chars),
    );
  }

  List<Widget> _buildRowList(List<String> chars) {
    List<Widget> list = [];
    for (int i = 0; i < chars.length; i++) {
      if (i > 0) list.add(const SizedBox(width: 4));
      final char = chars[i];
      final displayChar = isCapsLock ? char.toUpperCase() : char;
      list.add(_Key(
        label: displayChar,
        onHaptic: onHaptic,
        onTap: () {
          // 获取字符的 HID 信息
          final info = HidKeyMapper.charToHid(displayChar);
          if (info != null) {
            // 合并修饰键：用户修饰键 | 字符自带修饰键（如 Shift 用于大写）
            actions.sendKeyPress(modifiers | info.modifiers, [info.keyCode]);
          }
          onKeyTap();
        },
      ));
    }
    return list;
  }
}

class _NumberLayout extends StatelessWidget {
  final BluetoothActions actions;
  final VoidCallback? onHaptic;
  const _NumberLayout({required this.actions, this.onHaptic});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(["1", "2", "3"]),
        const SizedBox(height: 4),
        _buildRow(["4", "5", "6"]),
        const SizedBox(height: 4),
        _buildRow(["7", "8", "9"]),
        const SizedBox(height: 4),
        Row(
          children: [
            _Key(label: '.', onHaptic: onHaptic, onTap: () => actions.typeString(".")),
            const SizedBox(width: 4),
            _Key(label: '0', onHaptic: onHaptic, onTap: () => actions.typeString("0")),
            const SizedBox(width: 4),
            _Key(label: '⌫', onHaptic: onHaptic, onTap: () => actions.typeString("\b")),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> chars) {
    return Row(
      children: chars.map((c) => _Key(label: c, onHaptic: onHaptic, onTap: () => actions.typeString(c))).toList()
        .expand((w) => [w, const SizedBox(width: 4)]).toList()..removeLast(),
    );
  }
}

class _SymbolLayout extends StatelessWidget {
  final BluetoothActions actions;
  final VoidCallback? onHaptic;
  const _SymbolLayout({required this.actions, this.onHaptic});

  // 完整符号集，每行 8 个
  static const _row1 = ["!", "@", "#", "\$", "%", "^", "&", "*"];
  static const _row2 = ["(", ")", "-", "_", "+", "=", "{", "}"];
  static const _row3 = ["[", "]", "\\", "|", ";", ":", "'", "\""];
  static const _row4 = ["<", ">", ",", ".", "/", "?", "`", "~"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(_row1),
        const SizedBox(height: 4),
        _buildRow(_row2),
        const SizedBox(height: 4),
        _buildRow(_row3),
        const SizedBox(height: 4),
        _buildRow(_row4),
      ],
    );
  }

  Widget _buildRow(List<String> chars) {
    return Row(
      children: chars.map((c) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _Key(
            label: c,
            onHaptic: onHaptic,
            onTap: () => actions.typeString(c),
            flex: 1.0,
          ),
        ),
      )).toList(),
    );
  }
}

class _FnLayout extends StatelessWidget {
  final BluetoothActions actions;
  final int modifiers;
  final VoidCallback? onHaptic;
  const _FnLayout({required this.actions, required this.modifiers, this.onHaptic});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.5,
      children: List.generate(12, (index) {
        return _Key(label: 'F${index + 1}', isWide: true, onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x3A + index]));
      }),
    );
  }
}

class _NavLayout extends StatelessWidget {
  final BluetoothActions actions;
  final int modifiers;
  final VoidCallback? onHaptic;
  const _NavLayout({required this.actions, required this.modifiers, this.onHaptic});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 顶部行: Ins, Home, PgUp
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 64, child: _Key(label: 'Ins', isWide: true, onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x49]))),
            const SizedBox(width: 4),
            SizedBox(width: 64, child: _Key(label: 'Home', isWide: true, onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x4A]))),
            const SizedBox(width: 4),
            SizedBox(width: 64, child: _Key(label: 'PgUp', isWide: true, onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x4B]))),
          ],
        ),
        const SizedBox(height: 4),
        // 中间行: Del, End, PgDn
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 64, child: _Key(label: 'Del', isWide: true, onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x4C]))),
            const SizedBox(width: 4),
            SizedBox(width: 64, child: _Key(label: 'End', isWide: true, onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x4D]))),
            const SizedBox(width: 4),
            SizedBox(width: 64, child: _Key(label: 'PgDn', isWide: true, onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x4E]))),
          ],
        ),
        const SizedBox(height: 12),
        // 方向键区域
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 68),
            SizedBox(width: 60, child: _Key(label: '↑', onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x52]))),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 60, child: _Key(label: '←', onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x50]))),
            const SizedBox(width: 4),
            SizedBox(width: 60, child: _Key(label: '↓', onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x51]))),
            const SizedBox(width: 4),
            SizedBox(width: 60, child: _Key(label: '→', onHaptic: onHaptic, onTap: () => actions.sendKeyPress(modifiers, [0x4F]))),
          ],
        ),
      ],
    );
  }
}
