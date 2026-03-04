/// FlutterBluePlus 蓝牙扫描服务
/// 使用 flutter_blue_plus 插件实现完整的蓝牙设备扫描功能

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_info.dart';

/// FlutterBluePlus 服务类
/// 封装蓝牙扫描、连接状态监听等功能
class FlutterBluePlusService {
  static final FlutterBluePlusService _instance = FlutterBluePlusService._internal();
  factory FlutterBluePlusService() => _instance;
  FlutterBluePlusService._internal();

  /// 扫描结果流控制器
  final StreamController<List<DeviceInfo>> _scanResultsController =
      StreamController<List<DeviceInfo>>.broadcast();

  /// 扫描结果流
  Stream<List<DeviceInfo>> get scanResults => _scanResultsController.stream;

  /// 扫描状态流
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  /// 蓝牙适配器状态流
  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  /// 当前扫描到的设备列表
  final List<DeviceInfo> _discoveredDevices = [];

  /// 扫描订阅
  StreamSubscription? _scanSubscription;

  /// 是否正在扫描
  bool get isCurrentlyScanning => FlutterBluePlus.isScanningNow;

  /// 检查蓝牙权限
  Future<bool> checkPermissions() async {
    // 检查蓝牙是否可用
    if (await FlutterBluePlus.isSupported == false) {
      return false;
    }

    // 获取适配器状态
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      return false;
    }

    return true;
  }

  /// 开始扫描蓝牙设备
  /// [timeout] 扫描超时时间（秒）
  Future<void> startScan({int timeout = 15}) async {
    // 清除之前的扫描结果
    _discoveredDevices.clear();

    // 如果正在扫描，先停止
    if (isCurrentlyScanning) {
      await stopScan();
    }

    // 开始扫描
    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: timeout),
      androidUsesFineLocation: true,
    );

    // 监听扫描结果
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        for (final result in results) {
          final device = DeviceInfo.fromScanResult(result);
          _addOrUpdateDevice(device);
        }
      },
      onError: (error) {
        print('Scan error: $error');
      },
    );
  }

  /// 停止扫描
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
  }

  /// 获取已配对设备
  Future<List<DeviceInfo>> getBondedDevices() async {
    final bondedDevices = await FlutterBluePlus.bondedDevices;
    return bondedDevices.map((device) {
      return DeviceInfo(
        device: device,
        name: device.advName.isNotEmpty ? device.advName : 'Unknown Device',
        address: device.remoteId.str,
        isPaired: true,
      );
    }).toList();
  }

  /// 连接到设备
  /// [device] 要连接的设备
  Future<bool> connect(DeviceInfo device) async {
    try {
      final btDevice = device.device;
      if (btDevice == null) {
        print('Device is null');
        return false;
      }

      // 连接设备
      await btDevice.connect(
        autoConnect: false,
        mtu: null,
      );

      return true;
    } catch (e) {
      print('Connect error: $e');
      return false;
    }
  }

  /// 断开设备连接
  Future<bool> disconnect(DeviceInfo device) async {
    try {
      final btDevice = device.device;
      if (btDevice == null) return false;

      await btDevice.disconnect();
      return true;
    } catch (e) {
      print('Disconnect error: $e');
      return false;
    }
  }

  /// 添加或更新设备
  void _addOrUpdateDevice(DeviceInfo device) {
    final index = _discoveredDevices.indexWhere((d) => d.address == device.address);
    if (index >= 0) {
      // 更新现有设备
      _discoveredDevices[index] = device;
    } else {
      // 添加新设备
      _discoveredDevices.add(device);
    }

    // 通知监听器
    _scanResultsController.add(List.unmodifiable(_discoveredDevices));
  }

  /// 清理资源
  void dispose() {
    _scanSubscription?.cancel();
    _scanResultsController.close();
  }
}
