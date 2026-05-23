/// 蓝牙 HID 服务
/// 通过 MethodChannel 与 Android 原生代码通信
/// 实现蓝牙 HID 设备的连接和 HID 报告发送

import 'dart:async';
import 'package:flutter/services.dart';
import '../models/device_info.dart';
import '../utils/hid_key_mapper.dart';

/// MethodChannel 名称，必须与 Android 端一致
const String _channelName = 'com.example.bluepad/hid';

/// 蓝牙连接状态事件
class ConnectionEvent {
  final ConnectionState state;
  final String? address;
  ConnectionEvent(this.state, this.address);
}

/// 蓝牙 HID 服务类
/// 单例模式
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  /// MethodChannel 实例
  final MethodChannel _channel = const MethodChannel(_channelName);

  /// 连接状态流控制器
  final StreamController<ConnectionEvent> _connectionStateController =
      StreamController<ConnectionEvent>.broadcast();

  /// 连接状态流
  Stream<ConnectionEvent> get connectionEvent => _connectionStateController.stream;

  /// 是否已初始化
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 初始化 HID 服务
  Future<bool> initialize() async {
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      final result = await _channel.invokeMethod<bool>('initializeHid');
      _isInitialized = result ?? false;
      return _isInitialized;
    } on PlatformException catch (e) {
      print('Failed to initialize HID: ${e.message}');
      return false;
    }
  }

  /// 处理来自原生端的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    final String? address = call.arguments as String?;
    switch (call.method) {
      case 'onConnected':
        _connectionStateController.add(ConnectionEvent(ConnectionState.connected, address));
        break;
      case 'onDisconnected':
        _connectionStateController.add(ConnectionEvent(ConnectionState.disconnected, address));
        break;
      default:
        throw MissingPluginException('Method ${call.method} not implemented');
    }
  }

  /// 获取已配对的蓝牙设备
  Future<List<DeviceInfo>> getPairedDevices() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getPairedDevices');
      return result.map((device) {
        final map = device as Map<dynamic, dynamic>;
        return DeviceInfo.paired(
          name: map['name'] as String,
          address: map['address'] as String,
        );
      }).toList();
    } on PlatformException catch (e) {
      print('Failed to get paired devices: ${e.message}');
      return [];
    }
  }

  /// 连接设备
  Future<bool> connect(String address) async {
    try {
      _connectionStateController.add(ConnectionEvent(ConnectionState.connecting, address));
      final result = await _channel.invokeMethod<bool>('connect', {'address': address});
      return result ?? false;
    } on PlatformException catch (e) {
      _connectionStateController.add(ConnectionEvent(ConnectionState.disconnected, address));
      print('Failed to connect: ${e.message}');
      return false;
    }
  }

  /// 断开连接
  Future<bool> disconnect() async {
    try {
      final result = await _channel.invokeMethod<bool>('disconnect');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 获取连接状态
  Future<bool> getConnectionState() async {
    try {
      final result = await _channel.invokeMethod<bool>('getConnectionState');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to get connection state: ${e.message}');
      return false;
    }
  }

  // ==================== HID 报告发送 ====================

  /// 发送鼠标报告
  Future<bool> sendMouseReport({
    int buttons = 0,
    int dx = 0,
    int dy = 0,
    int wheel = 0,
    int hWheel = 0,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendMouseReport', {
        'buttons': buttons,
        'dx': dx.clamp(-127, 127),
        'dy': dy.clamp(-127, 127),
        'wheel': wheel.clamp(-127, 127),
        'hWheel': hWheel.clamp(-127, 127),
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 发送键盘报告
  Future<bool> sendKeyboardReport({
    int modifiers = 0,
    List<int> keys = const [],
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendKeyboardReport', {
        'modifiers': modifiers,
        'keys': keys.take(6).toList(),
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 发送多媒体/消费者控制报告
  Future<bool> sendConsumerReport(int mask) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendConsumerReport', {
        'mask': mask,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 发送按键（按下并释放）
  Future<bool> sendKeyPress(int modifiers, List<int> keys) async {
    try {
      // 发送按键按下
      await sendKeyboardReport(modifiers: modifiers, keys: keys);
      // 短暂延迟
      await Future.delayed(const Duration(milliseconds: 20));
      // 发送按键释放
      return await sendKeyboardReport(modifiers: 0, keys: []);
    } catch (e) {
      return false;
    }
  }

  /// 输入字符串（逐字符发送）
  Future<bool> typeString(String text, {int delayMs = 20}) async {
    try {
      final chars = text.split('');
      for (final char in chars) {
        final info = HidKeyMapper.charToHid(char);
        if (info != null) {
          await sendKeyboardReport(modifiers: info.modifiers, keys: [info.keyCode]);
          await Future.delayed(Duration(milliseconds: delayMs));
          await sendKeyboardReport(modifiers: 0, keys: []);
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 发送鼠标点击（按下并释放）
  Future<bool> sendMouseButton(MouseButton button, bool pressed) async {
    try {
      int mask = (button == MouseButton.left) ? 0x01 : (button == MouseButton.right ? 0x02 : 0x04);
      final result = await _channel.invokeMethod<bool>('sendMouseReport', {
        'buttons': pressed ? mask : 0,
        'dx': 0,
        'dy': 0,
        'wheel': 0,
        'hWheel': 0,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 振动反馈
  Future<void> vibrate(int duration) async {
    try {
      await _channel.invokeMethod('vibrate', {'duration': duration});
    } on PlatformException catch (e) {
      print('Failed to vibrate: ${e.message}');
    }
  }

  /// 清理资源
  void dispose() {
    _connectionStateController.close();
  }
}
