/// 后台服务状态管理 Provider
/// 管理蓝牙连接的后台保持

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/background_service.dart';
import '../services/settings_service.dart';
import 'bluetooth_provider.dart';

/// 设置服务 Provider（本地定义避免循环依赖）
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// 后台服务管理器 Provider
final backgroundServiceManagerProvider = Provider<BackgroundServiceManager>((ref) {
  final manager = BackgroundServiceManager();
  ref.onDispose(() {}); // 管理器不需要显式 dispose
  return manager;
});

/// 后台蓝牙管理器 Provider
final backgroundBluetoothManagerProvider = Provider<BackgroundBluetoothManager>((ref) {
  final manager = BackgroundBluetoothManager();
  manager.initialize();
  ref.onDispose(() {});
  return manager;
});

/// 后台服务运行状态 Provider
final backgroundServiceRunningProvider = StateProvider<bool>((ref) => false);

/// 后台服务操作 Provider
final backgroundServiceActionsProvider = Provider<BackgroundServiceActions>((ref) {
  return BackgroundServiceActions(ref);
});

class BackgroundServiceActions {
  final Ref _ref;

  BackgroundServiceActions(this._ref);

  BackgroundBluetoothManager get _bgManager => _ref.read(backgroundBluetoothManagerProvider);
  SettingsService get _settings => _ref.read(settingsServiceProvider);

  /// 启动后台服务
  Future<bool> startBackgroundService(String deviceAddress) async {
    final success = await _bgManager.startBackgroundConnection(deviceAddress);
    _ref.read(backgroundServiceRunningProvider.notifier).state = success;
    return success;
  }

  /// 停止后台服务
  Future<void> stopBackgroundService() async {
    await _bgManager.stopBackgroundConnection();
    _ref.read(backgroundServiceRunningProvider.notifier).state = false;
  }

  /// 检查后台服务状态
  Future<bool> checkBackgroundService() async {
    final running = await _bgManager.isRunning();
    _ref.read(backgroundServiceRunningProvider.notifier).state = running;
    return running;
  }

  /// 当连接成功时自动启动后台服务（如果设置开启）
  Future<void> onDeviceConnected(String deviceAddress) async {
    if (_settings.keepBackgroundConnection) {
      await startBackgroundService(deviceAddress);
    }
  }

  /// 当断开连接时停止后台服务
  Future<void> onDeviceDisconnected() async {
    await stopBackgroundService();
  }
}

/// 后台连接保持设置 Provider
final keepBackgroundConnectionProvider = StateNotifierProvider<KeepBackgroundConnectionNotifier, bool>((ref) {
  return KeepBackgroundConnectionNotifier(ref.watch(settingsServiceProvider));
});

class KeepBackgroundConnectionNotifier extends StateNotifier<bool> {
  final SettingsService _settings;

  KeepBackgroundConnectionNotifier(this._settings)
      : super(_settings.keepBackgroundConnection);

  Future<void> setEnabled(bool enabled) async {
    await _settings.setKeepBackgroundConnection(enabled);
    state = enabled;
  }

  void toggle() => setEnabled(!state);
}
