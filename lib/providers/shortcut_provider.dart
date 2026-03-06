import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shortcut_key.dart';
import '../models/shortcut_profile.dart';
import '../services/settings_service.dart';
import 'settings_provider.dart';  // 导入 settingsServiceProvider

/// 快捷键列表 Provider
final shortcutsProvider = StateNotifierProvider<ShortcutsNotifier, List<ShortcutKey>>((ref) {
  return ShortcutsNotifier(ref.watch(settingsServiceProvider));
});

class ShortcutsNotifier extends StateNotifier<List<ShortcutKey>> {
  final SettingsService _service;

  ShortcutsNotifier(this._service) : super(_service.shortcuts.isEmpty
      ? ShortcutKey.getDefaults()
      : _service.shortcuts);

  /// 添加快捷键
  Future<void> addShortcut(ShortcutKey shortcut) async {
    state = [...state, shortcut];
    await _service.setShortcuts(state);
  }

  /// 更新快捷键
  Future<void> updateShortcut(ShortcutKey shortcut) async {
    state = state.map((s) => s.id == shortcut.id ? shortcut : s).toList();
    await _service.setShortcuts(state);
  }

  /// 删除快捷键
  Future<void> deleteShortcut(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _service.setShortcuts(state);
  }

  /// 重新排序快捷键
  Future<void> reorderShortcuts(int oldIndex, int newIndex) async {
    final newList = List<ShortcutKey>.from(state);
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    state = newList;
    await _service.setShortcuts(state);
  }

  /// 重置为默认快捷键
  Future<void> resetToDefaults() async {
    state = ShortcutKey.getDefaults();
    await _service.setShortcuts(state);
  }
}

/// 配置文件 Provider
final profilesProvider = StateNotifierProvider<ProfilesNotifier, List<ShortcutProfile>>((ref) {
  return ProfilesNotifier(ref.watch(settingsServiceProvider));
});

class ProfilesNotifier extends StateNotifier<List<ShortcutProfile>> {
  final SettingsService _service;

  ProfilesNotifier(this._service) : super(_service.profiles);

  /// 添加配置文件
  Future<void> addProfile(ShortcutProfile profile) async {
    state = [...state, profile];
    await _service.setProfiles(state);
  }

  /// 更新配置文件
  Future<void> updateProfile(ShortcutProfile profile) async {
    state = state.map((p) => p.id == profile.id ? profile : p).toList();
    await _service.setProfiles(state);
  }

  /// 删除配置文件
  Future<void> deleteProfile(String id) async {
    // 不允许删除内置配置
    final profile = state.firstWhere((p) => p.id == id, orElse: () => state.first);
    if (profile.isBuiltIn) return;

    state = state.where((p) => p.id != id).toList();
    await _service.setProfiles(state);
  }

  /// 重置为默认配置
  Future<void> resetToDefaults() async {
    state = ShortcutProfile.getDefaults();
    await _service.setProfiles(state);
  }
}

/// 当前选中的配置文件 ID
final currentProfileIdProvider = StateProvider<String>((ref) {
  return 'global';
});