import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shortcut_key.dart';
import '../models/shortcut_profile.dart';
import '../services/settings_service.dart';
import 'settings_provider.dart';

// ==================== 当前选择状态 ====================

/// 当前选中的系统 Tab: 'windows' 或 'macos'
final currentSystemProvider = StateProvider<String>((ref) {
  // 默认根据设置的 osType 选择
  final osType = ref.watch(settingsProvider).osType;
  return osType == 'macOS' ? 'macos' : 'windows';
});

/// 当前选中的软件面板
final currentAppProvider = StateProvider<String>((ref) => 'global');

// ==================== 快捷键管理 ====================

/// 所有快捷键列表 Provider
final shortcutsProvider = StateNotifierProvider<ShortcutsNotifier, List<ShortcutKey>>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return ShortcutsNotifier(settingsService);
});

class ShortcutsNotifier extends StateNotifier<List<ShortcutKey>> {
  final SettingsService _service;

  ShortcutsNotifier(this._service) : super(_service.shortcuts.isEmpty
      ? ShortcutKey.getDefaults()
      : _service.shortcuts);

  /// 获取指定系统和面板的快捷键
  List<ShortcutKey> getShortcutsFor(String platform, String app) {
    return state.where((s) => s.platform == platform && s.app == app).toList();
  }

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

/// 过滤后的快捷键列表（根据当前系统和面板）
final filteredShortcutsProvider = Provider<List<ShortcutKey>>((ref) {
  final system = ref.watch(currentSystemProvider);
  final app = ref.watch(currentAppProvider);
  final allShortcuts = ref.watch(shortcutsProvider);

  return allShortcuts.where((s) =>
    s.platform == system && s.app == app
  ).toList();
});

// ==================== 软件面板管理 ====================

/// 软件面板列表 Provider
final appPanelsProvider = StateNotifierProvider<AppPanelsNotifier, List<AppPanel>>((ref) {
  return AppPanelsNotifier(ref.watch(settingsServiceProvider));
});

class AppPanelsNotifier extends StateNotifier<List<AppPanel>> {
  final SettingsService _service;

  AppPanelsNotifier(this._service) : super(_service.appPanels);

  /// 添加面板
  Future<void> addPanel(AppPanel panel) async {
    state = [...state, panel];
    await _service.setAppPanels(state);
  }

  /// 更新面板
  Future<void> updatePanel(AppPanel panel) async {
    state = state.map((p) => p.id == panel.id ? panel : p).toList();
    await _service.setAppPanels(state);
  }

  /// 删除面板（保留 global 面板不可删除）
  Future<void> deletePanel(String id) async {
    if (id == 'global') return;

    state = state.where((p) => p.id != id).toList();
    await _service.setAppPanels(state);
  }

  /// 重置为默认面板
  Future<void> resetToDefaults() async {
    state = AppPanel.getDefaults();
    await _service.setAppPanels(state);
  }
}

// ==================== 兼容旧版本的 Provider ====================

/// @deprecated 使用 currentSystemProvider 代替
final currentProfileIdProvider = StateProvider<String>((ref) {
  final system = ref.watch(currentSystemProvider);
  return system;
});

/// @deprecated 使用 appPanelsProvider 代替
final profilesProvider = appPanelsProvider;