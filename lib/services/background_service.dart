/// 后台服务
/// 保持蓝牙连接在后台运行
/// 使用 flutter_background_service 实现

import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

/// 后台服务配置
class BackgroundServiceConfig {
  /// 通知渠道 ID
  static const String notificationChannelId = 'bluepad_foreground';

  /// 通知渠道名称
  static const String notificationChannelName = 'BluePad 后台服务';

  /// 通知渠道描述
  static const String notificationChannelDesc = '保持蓝牙 HID 连接';

  /// 通知标题
  static const String notificationTitle = 'BluePad 正在运行';

  /// 通知内容
  static const String notificationContent = '蓝牙 HID 服务正在后台运行';

  /// 前台服务 ID
  static const int foregroundServiceId = 1001;
}

/// 后台服务管理器
class BackgroundServiceManager {
  static final BackgroundServiceManager _instance = BackgroundServiceManager._internal();
  factory BackgroundServiceManager() => _instance;
  BackgroundServiceManager._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 服务状态流
  Stream<Map<String, dynamic>?> get onDataReceived => _service.on('data');

  /// 初始化后台服务
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final result = await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: BackgroundServiceConfig.notificationChannelId,
        initialNotificationTitle: BackgroundServiceConfig.notificationTitle,
        initialNotificationContent: BackgroundServiceConfig.notificationContent,
        foregroundServiceNotificationId: BackgroundServiceConfig.foregroundServiceId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    _isInitialized = result;
    return result;
  }

  /// 启动后台服务
  Future<bool> start() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    return await _service.startService();
  }

  /// 停止后台服务
  Future<void> stop() async {
    _service.invoke('stop');
  }

  /// 发送数据到后台服务
  void sendData(Map<String, dynamic> data) {
    _service.invoke('data', data);
  }

  /// 检查服务是否正在运行
  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// 后台服务启动回调（必须在顶层或静态方法）
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Android 前台服务
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });

      // 设置前台服务通知
      service.setForegroundNotificationInfo(
        title: BackgroundServiceConfig.notificationTitle,
        content: BackgroundServiceConfig.notificationContent,
      );
    }

    // 监听停止命令
    service.on('stop').listen((event) {
      service.stopSelf();
    });

    // 监听数据
    service.on('data').listen((event) {
      // 处理从前台发送的数据
      _handleBackgroundData(event);
    });

    // 定时检查连接状态
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // 更新通知内容，显示连接状态
          service.setForegroundNotificationInfo(
            title: BackgroundServiceConfig.notificationTitle,
            content: '蓝牙 HID 连接活跃',
          );
        }
      }

      // 发送心跳到前台
      service.invoke('heartbeat', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  /// iOS 后台处理回调
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// 处理后台数据
  static void _handleBackgroundData(Map<String, dynamic>? data) {
    if (data == null) return;

    final action = data['action'] as String?;
    switch (action) {
      case 'connect':
        // 处理连接请求
        final address = data['address'] as String?;
        print('Background: Connect to $address');
        break;
      case 'disconnect':
        // 处理断开请求
        print('Background: Disconnect');
        break;
      case 'sendReport':
        // 处理发送 HID 报告
        final reportType = data['reportType'] as String?;
        final reportData = data['data'] as Map<String, dynamic>?;
        print('Background: Send $reportType report: $reportData');
        break;
    }
  }
}

/// 后台蓝牙连接管理器
/// 在后台保持蓝牙连接
class BackgroundBluetoothManager {
  static final BackgroundBluetoothManager _instance = BackgroundBluetoothManager._internal();
  factory BackgroundBluetoothManager() => _instance;
  BackgroundBluetoothManager._internal();

  final BackgroundServiceManager _service = BackgroundServiceManager();

  /// 当前连接的设备地址
  String? _connectedDeviceAddress;

  /// 是否正在尝试重连
  bool _isReconnecting = false;

  /// 重连尝试次数
  int _reconnectAttempts = 0;

  /// 最大重连次数
  static const int _maxReconnectAttempts = 3;

  /// 初始化
  Future<void> initialize() async {
    await _service.initialize();

    // 监听后台服务数据
    _service.onDataReceived.listen((data) {
      if (data != null) {
        _handleServiceData(data);
      }
    });
  }

  /// 启动后台连接保持
  Future<bool> startBackgroundConnection(String deviceAddress) async {
    _connectedDeviceAddress = deviceAddress;
    _reconnectAttempts = 0;

    // 发送连接信息到后台
    _service.sendData({
      'action': 'connect',
      'address': deviceAddress,
    });

    return await _service.start();
  }

  /// 停止后台连接
  Future<void> stopBackgroundConnection() async {
    _connectedDeviceAddress = null;
    _isReconnecting = false;

    _service.sendData({
      'action': 'disconnect',
    });

    await _service.stop();
  }

  /// 发送 HID 报告到后台
  void sendHidReport(String reportType, Map<String, dynamic> data) {
    _service.sendData({
      'action': 'sendReport',
      'reportType': reportType,
      'data': data,
    });
  }

  /// 处理后台服务数据
  void _handleServiceData(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'connectionLost':
        _handleConnectionLost();
        break;
      case 'heartbeat':
        // 处理心跳
        break;
    }
  }

  /// 处理连接丢失
  Future<void> _handleConnectionLost() async {
    if (_isReconnecting || _connectedDeviceAddress == null) return;

    _isReconnecting = true;

    while (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;

      // 尝试重连
      _service.sendData({
        'action': 'connect',
        'address': _connectedDeviceAddress,
        'attempt': _reconnectAttempts,
      });

      // 等待重连结果
      await Future.delayed(const Duration(seconds: 3));

      // 如果连接成功，退出重连循环
      // 这里需要实际的连接状态检查
    }

    _isReconnecting = false;
  }

  /// 检查后台服务是否运行
  Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}
