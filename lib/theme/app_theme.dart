import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// 应用主题配置
/// 对应 Android: ui/theme/Theme.kt
class AppTheme {
  /// 深色模式主题
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: DarkColors.accent,
    scaffoldBackgroundColor: DarkColors.bg,
    
    colorScheme: const ColorScheme.dark(
      primary: DarkColors.accent,
      secondary: DarkColors.purple,
      tertiary: DarkColors.green,
      surface: DarkColors.bg2,
      onSurface: DarkColors.text,
      onSurfaceVariant: DarkColors.text2,
      outline: DarkColors.border,
      surfaceContainerLowest: DarkColors.bg,
      surfaceContainerHigh: DarkColors.bg3,
    ),
    
    dividerTheme: const DividerThemeData(
      color: DarkColors.border,
      thickness: 1,
      space: 1,
    ),
    
    sliderTheme: const SliderThemeData(
      activeTrackColor: DarkColors.accent,
      inactiveTrackColor: DarkColors.border,
      thumbColor: DarkColors.accent,
      overlayColor: Color(0x293B82F6),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return DarkColors.accent;
        return DarkColors.border;
      }),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkColors.bg,
      foregroundColor: DarkColors.text,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: DarkColors.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );

  /// 浅色模式主题
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: LightColors.primary,
    scaffoldBackgroundColor: LightColors.bg,
    
    colorScheme: const ColorScheme.light(
      primary: LightColors.primary,
      secondary: LightColors.purple,
      tertiary: LightColors.green,
      surface: LightColors.bg2,
      onSurface: LightColors.text,
      onSurfaceVariant: LightColors.text2,
      outline: LightColors.border,
      surfaceContainerLowest: LightColors.bg,
      surfaceContainerHigh: LightColors.bg3,
    ),
    
    dividerTheme: const DividerThemeData(
      color: LightColors.border,
      thickness: 1,
      space: 1,
    ),
    
    sliderTheme: const SliderThemeData(
      activeTrackColor: LightColors.primary,
      inactiveTrackColor: LightColors.border,
      thumbColor: LightColors.primary,
      overlayColor: Color(0x293B82F6),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return LightColors.primary;
        return LightColors.border;
      }),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: LightColors.bg,
      foregroundColor: LightColors.text,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: LightColors.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );
}

/// 辅助圆角定义
class RoundedCornerShape extends RoundedRectangleBorder {
  RoundedCornerShape(double radius) : super(borderRadius: BorderRadius.circular(radius));
}
