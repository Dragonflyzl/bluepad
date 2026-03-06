/// 应用颜色配置
/// 对应 Android: ui/theme/Color.kt
/// 移植所有颜色定义到 Flutter

import 'package:flutter/material.dart';

/// 深色模式颜色（Cyber/Dark 主题）
class DarkColors {
  // 背景色
  static const Color bg = Color(0xFF0A0C10); // --bg
  static const Color bg1 = Color(0xFF0D0F13); // --bg1 (对话框背景)
  static const Color bg2 = Color(0xFF111318); // --bg2
  static const Color bg3 = Color(0xFF1E232E); // --bg3
  
  // 文字颜色
  static const Color text = Color(0xFFE2E8F0); // --text
  static const Color text2 = Color(0xFF94A3B8); // --text2
  static const Color text3 = Color(0xFF64748B); // --text3
  
  // 品牌/装饰色
  static const Color accent = Color(0xFF3B82F6); // --accent
  static const Color purple = Color(0xFF8B5CF6); // --accent2
  static const Color green = Color(0xFF10B981); // --accent3
  static const Color yellow = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  
  // 边框色
  static const Color border = Color(0xFF2A2F3A); // --border
}

/// 浅色模式颜色
class LightColors {
  // 背景色
  static const Color bg = Color(0xFFF8FAFC); // --bg-light
  static const Color bg1 = Color(0xFFFFFFFF); // --bg1-light (对话框背景)
  static const Color bg2 = Color(0xFFFFFFFF); // --bg2-light
  static const Color bg3 = Color(0xFFF1F5F9); // --bg3-light
  
  // 文字颜色
  static const Color text = Color(0xFF0F172A); // --text-light
  static const Color text2 = Color(0xFF475569); // --text2-light
  static const Color text3 = Color(0xFF94A3B8); // --text3-light
  
  // 品牌/装饰色
  static const Color primary = Color(0xFF3B82F6); // --primary-blue
  static const Color primarySubtle = Color(0xFFEFF6FF);
  static const Color primaryDark = Color(0xFF1E40AF);
  
  static const Color accent = Color(0xFF3B82F6);
  static const Color purple = Color(0xFFA855F7);
  static const Color green = Color(0xFF10B981);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  
  // 边框色
  static const Color border = Color(0xFFE2E8F0); // --border-light
  static const Color borderMedium = Color(0xFFCBD5E1);
}

/// 设备类型对应颜色
class DeviceTypeColors {
  static Color computer(bool isDark) => isDark ? DarkColors.accent : LightColors.primary;
  static Color phone(bool isDark) => isDark ? DarkColors.purple : LightColors.purple;
  static Color tablet(bool isDark) => isDark ? DarkColors.yellow : const Color(0xFFF59E0B);
  static Color unknown(bool isDark) => isDark ? DarkColors.text3 : LightColors.text3;
}
