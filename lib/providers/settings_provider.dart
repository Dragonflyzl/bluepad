import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/settings_service.dart';

/// 设置服务 Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// 设置状态类
class SettingsState {
  final double sensitivity;
  final double scrollSensitivity;
  final String osType;
  final bool tapToClick;
  final bool naturalScroll;
  final bool inertia;
  final bool haptic;
  final bool autoReconnect;
  final String language;
  final String themeMode;
  final bool clipboardAutoSync;
  final bool clipboardSensitiveDetection;
  final bool clipboardSaveHistory;

  SettingsState({
    required this.sensitivity,
    required this.scrollSensitivity,
    required this.osType,
    required this.tapToClick,
    required this.naturalScroll,
    required this.inertia,
    required this.haptic,
    required this.autoReconnect,
    required this.language,
    required this.themeMode,
    required this.clipboardAutoSync,
    required this.clipboardSensitiveDetection,
    required this.clipboardSaveHistory,
  });

  SettingsState copyWith({
    double? sensitivity,
    double? scrollSensitivity,
    String? osType,
    bool? tapToClick,
    bool? naturalScroll,
    bool? inertia,
    bool? haptic,
    bool? autoReconnect,
    String? language,
    String? themeMode,
    bool? clipboardAutoSync,
    bool? clipboardSensitiveDetection,
    bool? clipboardSaveHistory,
  }) {
    return SettingsState(
      sensitivity: sensitivity ?? this.sensitivity,
      scrollSensitivity: scrollSensitivity ?? this.scrollSensitivity,
      osType: osType ?? this.osType,
      tapToClick: tapToClick ?? this.tapToClick,
      naturalScroll: naturalScroll ?? this.naturalScroll,
      inertia: inertia ?? this.inertia,
      haptic: haptic ?? this.haptic,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      clipboardAutoSync: clipboardAutoSync ?? this.clipboardAutoSync,
      clipboardSensitiveDetection: clipboardSensitiveDetection ?? this.clipboardSensitiveDetection,
      clipboardSaveHistory: clipboardSaveHistory ?? this.clipboardSaveHistory,
    );
  }
}

/// 统一设置 Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(SettingsState(
    sensitivity: _service.sensitivity,
    scrollSensitivity: _service.scrollSensitivity,
    osType: _service.osType,
    tapToClick: _service.tapToClick,
    naturalScroll: _service.naturalScroll,
    inertia: _service.inertia,
    haptic: _service.haptic,
    autoReconnect: _service.autoReconnect,
    language: _service.language,
    themeMode: _service.themeMode,
    clipboardAutoSync: _service.clipboardAutoSync,
    clipboardSensitiveDetection: _service.clipboardSensitiveDetection,
    clipboardSaveHistory: _service.clipboardSaveHistory,
  ));

  Future<void> setSensitivity(double value) async {
    await _service.setSensitivity(value);
    state = state.copyWith(sensitivity: value);
  }

  Future<void> setScrollSensitivity(double value) async {
    await _service.setScrollSensitivity(value);
    state = state.copyWith(scrollSensitivity: value);
  }

  Future<void> setOsType(String value) async {
    await _service.setOsType(value);
    state = state.copyWith(osType: value);
  }

  Future<void> setTapToClick(bool value) async {
    await _service.setTapToClick(value);
    state = state.copyWith(tapToClick: value);
  }

  Future<void> setNaturalScroll(bool value) async {
    await _service.setNaturalScroll(value);
    state = state.copyWith(naturalScroll: value);
  }

  Future<void> setInertia(bool value) async {
    await _service.setInertia(value);
    state = state.copyWith(inertia: value);
  }

  Future<void> setHaptic(bool value) async {
    await _service.setHaptic(value);
    state = state.copyWith(haptic: value);
  }

  Future<void> setAutoReconnect(bool value) async {
    await _service.setAutoReconnect(value);
    state = state.copyWith(autoReconnect: value);
  }

  Future<void> setLanguage(String value) async {
    await _service.setLanguage(value);
    state = state.copyWith(language: value);
  }

  Future<void> setThemeMode(String value) async {
    await _service.setThemeMode(value);
    state = state.copyWith(themeMode: value);
  }

  Future<void> setClipboardAutoSync(bool value) async {
    await _service.setClipboardAutoSync(value);
    state = state.copyWith(clipboardAutoSync: value);
  }

  Future<void> setClipboardSensitiveDetection(bool value) async {
    await _service.setClipboardSensitiveDetection(value);
    state = state.copyWith(clipboardSensitiveDetection: value);
  }

  Future<void> setClipboardSaveHistory(bool value) async {
    await _service.setClipboardSaveHistory(value);
    state = state.copyWith(clipboardSaveHistory: value);
  }
}

// 保留其他特定的 Provider (可选，为保持兼容性)
final sensitivityProvider = Provider<double>((ref) => ref.watch(settingsProvider).sensitivity);
final osTypeProvider = Provider<String>((ref) => ref.watch(settingsProvider).osType);
// ... 其他简化的 Provider
