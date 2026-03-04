/// 蓝牙状态管理 Provider
/// 对应 Android: HidDevice + MainViewModel 中的蓝牙相关逻辑

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService, ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_info.dart';
import '../services/bluetooth_service.dart';
import '../services/flutter_blue_plus_service.dart';
import 'settings_provider.dart';

/// 蓝牙服务 Provider
final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final service = BluetoothService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// FlutterBluePlus 服务 Provider
final flutterBluePlusServiceProvider = Provider<FlutterBluePlusService>((ref) {
  final service = FlutterBluePlusService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 蓝牙适配器状态 Provider
final adapterStateProvider = StreamProvider<BluetoothAdapterState>((ref) {
  final service = ref.watch(flutterBluePlusServiceProvider);
  return service.adapterState;
});

/// 扫描结果流 Provider
final scanResultsProvider = StreamProvider<List<DeviceInfo>>((ref) {
  final service = ref.watch(flutterBluePlusServiceProvider);
  return service.scanResults;
});

/// 连接状态 Provider
final connectionStateProvider = StateNotifierProvider<ConnectionStateNotifier, ConnectionState>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  return ConnectionStateNotifier(ref, service);
});

class ConnectionStateNotifier extends StateNotifier<ConnectionState> {
  final BluetoothService _service;
  final Ref _ref;
  StreamSubscription? _subscription;

  ConnectionStateNotifier(this._ref, this._service) : super(ConnectionState.disconnected) {
    _subscription = _service.connectionEvent.listen((event) {
      state = event.state;
      if (event.state == ConnectionState.connected && event.address != null) {
        _updateConnectedDevice(event.address!);
      } else if (event.state == ConnectionState.disconnected) {
        _ref.read(connectedDeviceProvider.notifier).setDevice(null);
      }
    });
  }

  void setConnecting() {
    state = ConnectionState.connecting;
  }

  Future<void> _updateConnectedDevice(String address) async {
    // 1. 尝试获取设备信息
    await _ref.read(pairedDevicesProvider.notifier).refresh();
    
    DeviceInfo? findDevice() {
      final paired = _ref.read(pairedDevicesProvider);
      final discovered = _ref.read(discoveredDevicesProvider);
      try {
        return paired.firstWhere((d) => d.address == address);
      } catch (_) {
        try {
          return discovered.firstWhere((d) => d.address == address);
        } catch (_) {
          return null;
        }
      }
    }

    DeviceInfo? device = findDevice();
    
    // 如果名字还没加载出来，等待一会儿再试一次 (蓝牙广播常见延迟)
    if (device == null || device.name == "Unknown Device" || device.name.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await _ref.read(pairedDevicesProvider.notifier).refresh();
      device = findDevice();
    }

    if (device == null) {
      device = DeviceInfo.paired(name: "Connected Device", address: address);
    }
    
    _ref.read(connectedDeviceProvider.notifier).setDevice(device);

    // 2. 强效智能识别 OS
    final name = device.name.toLowerCase();
    final notifier = _ref.read(settingsProvider.notifier);
    
    if (name.contains("mac") || 
        name.contains("apple") || 
        name.contains("book") || 
        name.contains("air") || 
        name.contains("pro") || 
        name.contains("mini")) {
      notifier.setOsType("macOS");
    } else if (name.contains("win") || name.contains("pc") || name.contains("desktop")) {
      notifier.setOsType("Windows");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// 已连接设备 Provider
final connectedDeviceProvider = StateNotifierProvider<ConnectedDeviceNotifier, DeviceInfo?>((ref) {
  return ConnectedDeviceNotifier();
});

class ConnectedDeviceNotifier extends StateNotifier<DeviceInfo?> {
  ConnectedDeviceNotifier() : super(null);
  void setDevice(DeviceInfo? device) => state = device;
}

/// 已配对设备列表 Provider
final pairedDevicesProvider = StateNotifierProvider<PairedDevicesNotifier, List<DeviceInfo>>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  return PairedDevicesNotifier(service);
});

class PairedDevicesNotifier extends StateNotifier<List<DeviceInfo>> {
  final BluetoothService _service;
  PairedDevicesNotifier(this._service) : super([]);

  Future<void> refresh() async {
    final devices = await _service.getPairedDevices();
    state = devices;
  }
}

/// 扫描发现的设备 Provider
final discoveredDevicesProvider = StateNotifierProvider<DiscoveredDevicesNotifier, List<DeviceInfo>>((ref) {
  return DiscoveredDevicesNotifier();
});

class DiscoveredDevicesNotifier extends StateNotifier<List<DeviceInfo>> {
  DiscoveredDevicesNotifier() : super([]);
  void setDevices(List<DeviceInfo> devices) => state = devices;
  void clear() => state = [];
}

/// 蓝牙操作 Provider
final bluetoothActionsProvider = Provider<BluetoothActions>((ref) {
  return BluetoothActions(ref);
});

class BluetoothActions {
  final Ref _ref;
  BluetoothActions(this._ref);

  BluetoothService get _service => _ref.read(bluetoothServiceProvider);
  FlutterBluePlusService get _fbsService => _ref.read(flutterBluePlusServiceProvider);

  Future<bool> checkBluetooth() async => await _fbsService.checkPermissions();

  Future<void> startScan({int timeout = 15}) async {
    _ref.read(discoveredDevicesProvider.notifier).clear();
    await _ref.read(pairedDevicesProvider.notifier).refresh();
    final pairedAddresses = _ref.read(pairedDevicesProvider).map((d) => d.address).toSet();

    await _fbsService.startScan(timeout: timeout);
    _fbsService.scanResults.listen((devices) {
      final filtered = devices.where((d) => !pairedAddresses.contains(d.address)).toList();
      _ref.read(discoveredDevicesProvider.notifier).setDevices(filtered);
    });
  }

  Future<void> stopScan() async {
    await _fbsService.stopScan();
  }

  Future<bool> connect(DeviceInfo device) async {
    _ref.read(connectionStateProvider.notifier).setConnecting();
    
    // 第一次尝试
    bool requestSent = await _service.connect(device.address);
    print("[FBP] Connection request sent (1st): $requestSent");
    
    if (!requestSent) {
      // 可能是 Profile 正在初始化，等待 1 秒后最后重试一次
      await Future.delayed(const Duration(milliseconds: 1000));
      requestSent = await _service.connect(device.address);
      print("[FBP] Connection request sent (2nd): $requestSent");
    }

    final completer = Completer<bool>();
    StreamSubscription? subscription;

    subscription = _service.connectionEvent.listen((event) {
      print("[FBP] Connection event: ${event.state} for ${event.address}");
      if (event.address == device.address) {
        if (event.state == ConnectionState.connected) {
          if (!completer.isCompleted) completer.complete(true);
          subscription?.cancel();
        } else if (event.state == ConnectionState.disconnected) {
          if (!completer.isCompleted) completer.complete(false);
          subscription?.cancel();
        }
      }
    });

    try {
      final result = await completer.future.timeout(const Duration(seconds: 10));
      return result;
    } catch (e) {
      print("[FBP] Connection timeout or error: $e");
      subscription?.cancel();
      return false;
    }
  }

  Future<bool> disconnect() async => await _service.disconnect();

  // ==================== HID 报告发送 ====================

  void sendMouseMove(double dx, double dy, {int buttons = 0}) {
    _service.sendMouseReport(buttons: buttons, dx: dx.toInt(), dy: dy.toInt());
  }

  void sendScroll(double vertical, {double horizontal = 0}) {
    _service.sendMouseReport(wheel: vertical.toInt(), hWheel: horizontal.toInt());
  }

  Future<bool> sendKeyPress(int modifiers, List<int> keyCodes) async {
    return await _service.sendKeyPress(modifiers, keyCodes);
  }

  Future<bool> sendConsumerReport(int mask) async {
    return await _service.sendConsumerReport(mask);
  }

  void sendZoom(double delta, {bool isStart = false, bool isEnd = false}) {
    // Zoom 通常映射为 Ctrl + Wheel 或者特殊的系统手势
    // 这里简单映射为垂直滚动，实际可能需要更复杂的 HID 映射
    if (isStart || isEnd) return;
    _service.sendMouseReport(wheel: (delta * 10).toInt());
  }

  void sendThreeFingerTap() {
    // 三指轻点通常映射为 Win+S 或搜索键，这里发送 Win 键
    _service.sendKeyPress(0x08, []);
  }

  Future<bool> typeString(String text, {int delayMs = 25}) async {
    return await _service.typeString(text, delayMs: delayMs);
  }

  Future<void> vibrate(int duration) async {
    await _service.vibrate(duration);
  }
}
