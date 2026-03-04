/// 剪贴板历史状态管理 Provider
/// 对应 Android: MainViewModel 中的剪贴板相关逻辑
///
/// 使用 DatabaseService 操作剪贴板历史记录
/// 支持自动同步系统剪贴板

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clipboard_item.dart';
import '../services/database_service.dart';
import '../services/clipboard_service.dart';
import '../services/settings_service.dart';
import 'bluetooth_provider.dart';

/// 设置服务 Provider（本地定义避免循环依赖）
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// 剪贴板服务 Provider
final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 数据库服务 Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// 剪贴板历史列表 Provider
/// 对应 Android: clipboardHistory Flow
final clipboardHistoryProvider = StateNotifierProvider<ClipboardHistoryNotifier, List<ClipboardItem>>((ref) {
  return ClipboardHistoryNotifier(
    ref.watch(databaseServiceProvider),
    ref.watch(clipboardServiceProvider),
    ref.watch(settingsServiceProvider),
  );
});

class ClipboardHistoryNotifier extends StateNotifier<List<ClipboardItem>> {
  final DatabaseService _database;
  final ClipboardService _clipboardService;
  final SettingsService _settings;
  StreamSubscription<String>? _clipboardSubscription;

  ClipboardHistoryNotifier(
    this._database,
    this._clipboardService,
    this._settings,
  ) : super([]) {
    // 初始化时加载历史记录
    _loadHistory();
    // 如果自动同步开启，开始监听
    if (_settings.clipboardAutoSync) {
      _startAutoSync();
    }
  }

  /// 加载历史记录
  Future<void> _loadHistory() async {
    final items = await _database.getAllClipboardItems();
    state = items;
  }

  /// 开始自动同步
  void _startAutoSync() {
    _clipboardService.startMonitoring();
    _clipboardSubscription = _clipboardService.onClipboardChanged.listen((content) {
      _addItemInternal(content, fromSystem: true);
    });
  }

  /// 停止自动同步
  void _stopAutoSync() {
    _clipboardSubscription?.cancel();
    _clipboardSubscription = null;
    _clipboardService.stopMonitoring();
  }

  /// 设置自动同步
  void setAutoSync(bool enabled) {
    if (enabled) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    await _loadHistory();
  }

  /// 添加剪贴板项（内部方法）
  Future<void> _addItemInternal(String content, {bool fromSystem = false}) async {
    // 检查是否已存在相同内容
    final exists = state.any((item) => item.content == content);
    if (exists) return;

    final item = ClipboardItem(
      content: content,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      preview: content.length > 50 ? '${content.substring(0, 50)}...' : content,
      charCount: content.length,
      contentType: _detectContentType(content),
      source: fromSystem ? 'system' : 'manual',
    );

    final id = await _database.insertClipboardItem(item);
    final newItem = item.copyWith(id: id);
    state = [newItem, ...state];
  }

  /// 添加剪贴板项（公开方法）
  Future<void> addItem(String content) async {
    await _addItemInternal(content, fromSystem: false);
    // 同时写入系统剪贴板
    await _clipboardService.writeClipboard(content);
  }

  /// 删除剪贴板项
  Future<void> deleteItem(int id) async {
    await _database.deleteClipboardItem(id);
    state = state.where((item) => item.id != id).toList();
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(ClipboardItem item) async {
    final updated = item.copyWith(isFavorite: !item.isFavorite);
    await _database.updateClipboardItem(updated);
    state = state.map((i) => i.id == item.id ? updated : i).toList();
  }

  /// 清空历史记录（保留收藏）
  Future<void> clearHistory() async {
    await _database.clearClipboardHistory();
    // 只保留收藏的项目
    state = state.where((item) => item.isFavorite).toList();
  }

  /// 清空所有记录
  Future<void> clearAll() async {
    await _database.deleteAllClipboardItems();
    state = [];
  }

  /// 搜索剪贴板内容
  Future<void> search(String query) async {
    if (query.isEmpty) {
      await _loadHistory();
      return;
    }
    final results = await _database.searchClipboardItems(query);
    state = results;
  }

  /// 检测内容类型
  ClipboardContentType _detectContentType(String content) {
    if (content.startsWith('http://') || content.startsWith('https://')) {
      return ClipboardContentType.url;
    }
    if (content.contains('@') && content.contains('.')) {
      // 简单邮箱检测
      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
      if (emailRegex.hasMatch(content.trim())) {
        return ClipboardContentType.email;
      }
    }
    if (content.contains('{') || content.contains('}') ||
        content.contains('function') || content.contains('class') ||
        content.contains('def ') || content.contains('import ')) {
      return ClipboardContentType.code;
    }
    return ClipboardContentType.text;
  }

  @override
  void dispose() {
    _stopAutoSync();
    super.dispose();
  }
}

/// 自动同步状态 Provider
final clipboardAutoSyncProvider = StateNotifierProvider<ClipboardAutoSyncNotifier, bool>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return ClipboardAutoSyncNotifier(settings, ref);
});

class ClipboardAutoSyncNotifier extends StateNotifier<bool> {
  final SettingsService _settings;
  final Ref _ref;

  ClipboardAutoSyncNotifier(this._settings, this._ref) : super(_settings.clipboardAutoSync);

  Future<void> setEnabled(bool enabled) async {
    await _settings.setClipboardAutoSync(enabled);
    // 同步控制剪贴板历史记录器的自动同步
    _ref.read(clipboardHistoryProvider.notifier).setAutoSync(enabled);
    state = enabled;
  }

  void toggle() => setEnabled(!state);
}

/// 剪贴板操作 Provider
final clipboardActionsProvider = Provider((ref) {
  return ClipboardActions(ref);
});

class ClipboardActions {
  final Ref _ref;

  ClipboardActions(this._ref);

  ClipboardService get _service => _ref.read(clipboardServiceProvider);

  /// 复制到系统剪贴板
  /// 对应 Android: MainViewModel.copyToClipboard()
  Future<void> copyToClipboard(String text) async {
    await _service.writeClipboard(text);
    // 同时添加到历史记录
    await _ref.read(clipboardHistoryProvider.notifier).addItem(text);
  }

  /// 从历史记录粘贴
  /// 通过 HID 键盘输入发送内容
  Future<void> pasteFromHistory(ClipboardItem item) async {
    final bluetoothActions = _ref.read(bluetoothActionsProvider);
    // 使用蓝牙服务输入字符串
    await bluetoothActions.typeString(item.content);
  }

  /// 手动检查剪贴板
  Future<void> checkClipboard() async {
    final content = await _service.readClipboard();
    if (content != null && content.isNotEmpty) {
      await _ref.read(clipboardHistoryProvider.notifier).addItem(content);
    }
  }
}
