/// 设置服务
/// 对应 Android: PreferencesManager
/// 使用 shared_preferences 替代 DataStore
///
/// Kotlin DataStore 的 Flow 特性在 Flutter 中的映射：
/// - Kotlin: Flow<T>  →  Dart: Stream<T> 或 ValueNotifier<T>
/// - Kotlin: suspend  →  Dart: async/await
/// - Kotlin: .first()  →  Dart: .first 或 await stream.first
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shortcut_key.dart';
import '../models/shortcut_profile.dart';

/// 设置服务类
/// 单例模式
class SettingsService {
  static SharedPreferences? _prefs;
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() => _instance;

  SettingsService._internal();

  /// 初始化设置服务
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError('SettingsService 未初始化，请先调用 init()');
    }
    return _prefs!;
  }

  // ==================== 设置键常量 ====================
  static const String _keySensitivity = 'sensitivity';
  static const String _keyScrollSensitivity = 'scroll_sensitivity';
  static const String _keyOsType = 'os_type';
  static const String _keyShortcuts = 'shortcuts_json';
  static const String _keyLastDevice = 'last_device';
  static const String _keyTapToClick = 'tap_to_click';
  static const String _keyNaturalScroll = 'natural_scroll';
  static const String _keyInertia = 'inertia';
  static const String _keyHaptic = 'haptic';
  static const String _keyAutoReconnect = 'auto_reconnect';
  static const String _keyLanguage = 'app_language';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyProfiles = 'profiles_json';
  static const String _keyClipboardAutoSync = 'clipboard_auto_sync';
  static const String _keyClipboardSensitiveDetection = 'clipboard_sensitive_detection';
  static const String _keyClipboardSaveHistory = 'clipboard_save_history';
  static const String _keyKeepBackgroundConnection = 'keep_background_connection';

  // ==================== Stream 控制器（模拟 Kotlin Flow）====================
  final Map<String, StreamController<dynamic>> _controllers = {};

  /// 获取或创建 StreamController
  StreamController<T> _getController<T>(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = StreamController<T>.broadcast();
    }
    return _controllers[key]! as StreamController<T>;
  }

  /// 通知值变化（触发 Stream）
  void _notifyChange<T>(String key, T value) {
    if (_controllers.containsKey(key)) {
      _controllers[key]!.add(value);
    }
  }

  // ==================== 触控板设置 ====================

  /// 触摸灵敏度
  /// 默认值：1.5
  /// 对应 Kotlin: getSensitivity(): Flow<Float>
  double get sensitivity => _preferences.getDouble(_keySensitivity) ?? 1.5;

  Stream<double> get sensitivityStream => _getController<double>(_keySensitivity).stream;

  Future<void> setSensitivity(double value) async {
    await _preferences.setDouble(_keySensitivity, value);
    _notifyChange(_keySensitivity, value);
  }

  /// 滚动灵敏度
  /// 默认值：1.0
  double get scrollSensitivity => _preferences.getDouble(_keyScrollSensitivity) ?? 1.0;

  Stream<double> get scrollSensitivityStream => _getController<double>(_keyScrollSensitivity).stream;

  Future<void> setScrollSensitivity(double value) async {
    await _preferences.setDouble(_keyScrollSensitivity, value);
    _notifyChange(_keyScrollSensitivity, value);
  }

  /// 操作系统类型（影响快捷键映射）
  /// 可选值: 'win', 'mac', 'linux'
  /// 默认值：'win'
  String get osType => _preferences.getString(_keyOsType) ?? 'win';

  Stream<String> get osTypeStream => _getController<String>(_keyOsType).stream;

  Future<void> setOsType(String value) async {
    await _preferences.setString(_keyOsType, value);
    _notifyChange(_keyOsType, value);
  }

  // ==================== 功能开关 ====================

  /// 点击触摸（轻触点击）
  /// 默认值：true
  bool get tapToClick => _preferences.getBool(_keyTapToClick) ?? true;

  Stream<bool> get tapToClickStream => _getController<bool>(_keyTapToClick).stream;

  Future<void> setTapToClick(bool value) async {
    await _preferences.setBool(_keyTapToClick, value);
    _notifyChange(_keyTapToClick, value);
  }

  /// 自然滚动（类似 macOS）
  /// 默认值：true
  bool get naturalScroll => _preferences.getBool(_keyNaturalScroll) ?? true;

  Stream<bool> get naturalScrollStream => _getController<bool>(_keyNaturalScroll).stream;

  Future<void> setNaturalScroll(bool value) async {
    await _preferences.setBool(_keyNaturalScroll, value);
    _notifyChange(_keyNaturalScroll, value);
  }

  /// 惯性滚动
  /// 默认值：false
  bool get inertia => _preferences.getBool(_keyInertia) ?? false;

  Stream<bool> get inertiaStream => _getController<bool>(_keyInertia).stream;

  Future<void> setInertia(bool value) async {
    await _preferences.setBool(_keyInertia, value);
    _notifyChange(_keyInertia, value);
  }

  /// 触觉反馈
  /// 默认值：true
  bool get haptic => _preferences.getBool(_keyHaptic) ?? true;

  Stream<bool> get hapticStream => _getController<bool>(_keyHaptic).stream;

  Future<void> setHaptic(bool value) async {
    await _preferences.setBool(_keyHaptic, value);
    _notifyChange(_keyHaptic, value);
  }

  /// 自动重连
  /// 默认值：true
  bool get autoReconnect => _preferences.getBool(_keyAutoReconnect) ?? true;

  Stream<bool> get autoReconnectStream => _getController<bool>(_keyAutoReconnect).stream;

  Future<void> setAutoReconnect(bool value) async {
    await _preferences.setBool(_keyAutoReconnect, value);
    _notifyChange(_keyAutoReconnect, value);
  }

  // ==================== 应用设置 ====================

  /// 语言设置
  /// 可选值: 'zh' (简体中文), 'zh-TW' (繁体中文), 'en' (英文)
  /// 默认值：'zh'
  String get language => _preferences.getString(_keyLanguage) ?? 'zh';

  Stream<String> get languageStream => _getController<String>(_keyLanguage).stream;

  Future<void> setLanguage(String value) async {
    await _preferences.setString(_keyLanguage, value);
    _notifyChange(_keyLanguage, value);
  }

  /// 主题模式
  /// 可选值: 'dark', 'light', 'auto'
  /// 默认值：'dark'
  String get themeMode => _preferences.getString(_keyThemeMode) ?? 'dark';

  Stream<String> get themeModeStream => _getController<String>(_keyThemeMode).stream;

  Future<void> setThemeMode(String value) async {
    await _preferences.setString(_keyThemeMode, value);
    _notifyChange(_keyThemeMode, value);
  }

  // ==================== 剪贴板设置 ====================

  /// 剪贴板自动同步
  /// 默认值：false
  bool get clipboardAutoSync => _preferences.getBool(_keyClipboardAutoSync) ?? false;

  Stream<bool> get clipboardAutoSyncStream => _getController<bool>(_keyClipboardAutoSync).stream;

  Future<void> setClipboardAutoSync(bool value) async {
    await _preferences.setBool(_keyClipboardAutoSync, value);
    _notifyChange(_keyClipboardAutoSync, value);
  }

  /// 敏感信息检测
  /// 默认值：true
  bool get clipboardSensitiveDetection =>
      _preferences.getBool(_keyClipboardSensitiveDetection) ?? true;

  Stream<bool> get clipboardSensitiveDetectionStream =>
      _getController<bool>(_keyClipboardSensitiveDetection).stream;

  Future<void> setClipboardSensitiveDetection(bool value) async {
    await _preferences.setBool(_keyClipboardSensitiveDetection, value);
    _notifyChange(_keyClipboardSensitiveDetection, value);
  }

  /// 保存历史记录
  /// 默认值：true
  bool get clipboardSaveHistory => _preferences.getBool(_keyClipboardSaveHistory) ?? true;

  Stream<bool> get clipboardSaveHistoryStream => _getController<bool>(_keyClipboardSaveHistory).stream;

  Future<void> setClipboardSaveHistory(bool value) async {
    await _preferences.setBool(_keyClipboardSaveHistory, value);
    _notifyChange(_keyClipboardSaveHistory, value);
  }

  // ==================== 后台服务设置 ====================

  /// 保持后台连接
  /// 默认值：true
  bool get keepBackgroundConnection =>
      _preferences.getBool(_keyKeepBackgroundConnection) ?? true;

  Stream<bool> get keepBackgroundConnectionStream =>
      _getController<bool>(_keyKeepBackgroundConnection).stream;

  Future<void> setKeepBackgroundConnection(bool value) async {
    await _preferences.setBool(_keyKeepBackgroundConnection, value);
    _notifyChange(_keyKeepBackgroundConnection, value);
  }

  // ==================== 快捷键配置 ====================

  /// 获取所有快捷键
  /// 对应 Kotlin: getShortcuts(): Flow<List<ShortcutKey>>
  List<ShortcutKey> get shortcuts {
    final jsonString = _preferences.getString(_keyShortcuts);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => ShortcutKey.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<ShortcutKey>> get shortcutsStream => _getController<List<ShortcutKey>>(_keyShortcuts).stream;

  Future<void> setShortcuts(List<ShortcutKey> shortcuts) async {
    final jsonString = jsonEncode(shortcuts.map((e) => e.toJson()).toList());
    await _preferences.setString(_keyShortcuts, jsonString);
    _notifyChange(_keyShortcuts, shortcuts);
  }

  // ==================== 配置文件 ====================

  /// 获取所有配置文件
  List<ShortcutProfile> get profiles {
    final jsonString = _preferences.getString(_keyProfiles);
    if (jsonString == null) return ShortcutProfile.getDefaults();
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => ShortcutProfile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return ShortcutProfile.getDefaults();
    }
  }

  Stream<List<ShortcutProfile>> get profilesStream => _getController<List<ShortcutProfile>>(_keyProfiles).stream;

  Future<void> setProfiles(List<ShortcutProfile> profiles) async {
    final jsonString = jsonEncode(profiles.map((e) => e.toJson()).toList());
    await _preferences.setString(_keyProfiles, jsonString);
    _notifyChange(_keyProfiles, profiles);
  }

  // ==================== 设备管理 ====================

  /// 最后连接的设备地址
  String? get lastDevice => _preferences.getString(_keyLastDevice);

  Future<void> setLastDevice(String? address) async {
    if (address == null) {
      await _preferences.remove(_keyLastDevice);
    } else {
      await _preferences.setString(_keyLastDevice, address);
    }
  }

  // ==================== 配置导入导出 ====================

  /// 导出所有配置为 JSON 字符串
  /// 对应 Kotlin: exportConfig()
  String exportConfig() {
    final config = {
      'version': 1,
      'sensitivity': sensitivity,
      'scrollSensitivity': scrollSensitivity,
      'osType': osType,
      'tapToClick': tapToClick,
      'naturalScroll': naturalScroll,
      'inertia': inertia,
      'haptic': haptic,
      'autoReconnect': autoReconnect,
      'language': language,
      'themeMode': themeMode,
      'shortcuts': shortcuts.map((e) => e.toJson()).toList(),
      'profiles': profiles.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(config);
  }

  /// 从 JSON 字符串导入配置
  /// 对应 Kotlin: importConfig(jsonString)
  /// 返回是否成功
  Future<bool> importConfig(String jsonString) async {
    try {
      final config = jsonDecode(jsonString) as Map<String, dynamic>;

      await setSensitivity((config['sensitivity'] as num?)?.toDouble() ?? 1.5);
      await setScrollSensitivity((config['scrollSensitivity'] as num?)?.toDouble() ?? 1.0);
      await setOsType(config['osType'] as String? ?? 'win');
      await setTapToClick(config['tapToClick'] as bool? ?? true);
      await setNaturalScroll(config['naturalScroll'] as bool? ?? true);
      await setInertia(config['inertia'] as bool? ?? false);
      await setHaptic(config['haptic'] as bool? ?? true);
      await setAutoReconnect(config['autoReconnect'] as bool? ?? true);
      await setLanguage(config['language'] as String? ?? 'zh');
      await setThemeMode(config['themeMode'] as String? ?? 'dark');

      final shortcutsJson = config['shortcuts'] as List<dynamic>?;
      if (shortcutsJson != null) {
        await setShortcuts(
          shortcutsJson.map((e) => ShortcutKey.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }

      final profilesJson = config['profiles'] as List<dynamic>?;
      if (profilesJson != null) {
        await setProfiles(
          profilesJson.map((e) => ShortcutProfile.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
