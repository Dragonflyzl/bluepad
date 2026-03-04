import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/l10n_utils.dart';

/// 底部导航栏组件
/// 对应 Android: NavigationComponents.kt 中的 TabBar
class TabItem {
  final IconData icon;
  final String label;

  const TabItem({
    required this.icon,
    required this.label,
  });
}

class AppTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<TabItem> tabs = [
      TabItem(icon: Icons.touch_app, label: context.s('nav_touchpad')),
      TabItem(icon: Icons.keyboard, label: context.s('nav_keyboard')),
      TabItem(icon: Icons.airplay, label: context.s('nav_air_mouse')),
      TabItem(icon: Icons.grid_view, label: context.s('nav_shortcuts')),
      TabItem(icon: Icons.assignment, label: context.s('nav_clipboard')),
      TabItem(icon: Icons.settings, label: context.s('nav_settings')),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariant = isDark ? DarkColors.bg3 : LightColors.bg3;
    final outlineColor = isDark ? DarkColors.border : LightColors.border;
    final accentColor = isDark ? DarkColors.accent : LightColors.primary;
    final onSurfaceVariant = isDark ? DarkColors.text2 : LightColors.text2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: outlineColor),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = index == currentIndex;
            
            // 样式对齐 Kotlin: 选中时为背景浅色+边框
            final bgColor = isSelected ? accentColor.withOpacity(0.12) : Colors.transparent;
            final borderColor = isSelected ? accentColor.withOpacity(0.3) : Colors.transparent;
            final contentColor = isSelected ? accentColor : onSurfaceVariant;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        color: contentColor,
                        size: 18,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
