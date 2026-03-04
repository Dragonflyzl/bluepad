import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'services/settings_service.dart';
import 'services/bluetooth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 初始化设置服务
  final settingsService = SettingsService();
  await settingsService.init();

  // 2. 初始化蓝牙 HID 服务
  final bluetoothService = BluetoothService();
  await bluetoothService.initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    // 主题模式解析
    ThemeMode themeMode;
    switch (settings.themeMode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    // 语言环境解析
    Locale? locale;
    if (settings.language == 'zh') {
      locale = const Locale('zh', 'CN');
    } else if (settings.language == 'en') {
      locale = const Locale('en', 'US');
    }

    return MaterialApp(
      title: 'BluePad',
      debugShowCheckedModeBanner: false,
      
      // 主题配置
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // 国际化配置
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      
      home: const MainScreen(),
    );
  }
}
