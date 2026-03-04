/// 主屏幕
/// 对应 Android: MainScreen.kt
/// 包含底部导航栏和各个功能页面

import 'package:flutter/material.dart';
import '../widgets/connection_bar.dart';
import '../widgets/tab_bar.dart';
import 'touchpad_screen.dart';
import 'keyboard_screen.dart';
import 'air_mouse_screen.dart';
import 'shortcuts_screen.dart';
import 'clipboard_screen.dart';
import 'settings_screen.dart';

/// 主屏幕组件
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TouchpadScreen(),
    KeyboardScreen(),
    AirMouseScreen(),
    ShortcutsScreen(),
    ClipboardScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    '触控板',
    '键盘',
    '空中鼠标',
    '快捷键',
    '剪贴板',
    '设置',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 连接状态栏
            const ConnectionBar(),

            // 导航栏
            AppTabBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),

            // 页面内容
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
