import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';

extension LocalizedStrings on BuildContext {
  /// 获取当前语言环境下的字符串
  String s(String key) {
    // 通过 Provider 获取当前语言设置
    // 注意：在 build 方法外使用需谨慎
    try {
      final container = ProviderScope.containerOf(this, listen: false);
      final locale = container.read(settingsProvider).language;
      return AppStrings.of(key, locale);
    } catch (e) {
      return AppStrings.of(key, 'zh'); // 默认中文
    }
  }
}

/// WidgetRef 扩展，方便在 ConsumerWidget 中使用
extension LocalizedStringsRef on WidgetRef {
  String s(String key) {
    final locale = watch(settingsProvider).language;
    return AppStrings.of(key, locale);
  }
}
