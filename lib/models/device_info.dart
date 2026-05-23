import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 连接状态枚举
enum ConnectionState {
  disconnected,  // 未连接
  connecting,    // 连接中
  connected,     // 已连接
}

/// 鼠标按钮枚举
enum MouseButton {
  left,    // 左键
  middle,  // 中键
  right,   // 右键
}

/// 设备信息类
class DeviceInfo {
  final BluetoothDevice? device;
  final String name;
  final String address;
  final bool isConnected;
  final int lastConnected;
  final int? rssi;
  final bool isPaired;

  const DeviceInfo({
    this.device,
    required this.name,
    required this.address,
    this.isConnected = false,
    this.lastConnected = 0,
    this.rssi,
    this.isPaired = false,
  });

  factory DeviceInfo.fromScanResult(ScanResult result) {
    final adv = result.advertisementData;
    return DeviceInfo(
      device: result.device,
      name: adv.advName.isNotEmpty ? adv.advName : 'Unknown Device',
      address: result.device.remoteId.str,
      rssi: result.rssi,
      isPaired: false,
    );
  }

  factory DeviceInfo.paired({
    required String name,
    required String address,
  }) {
    return DeviceInfo(
      name: name,
      address: address,
      isPaired: true,
    );
  }

  DeviceInfo copyWith({
    BluetoothDevice? device,
    String? name,
    String? address,
    bool? isConnected,
    int? lastConnected,
    int? rssi,
    bool? isPaired,
  }) {
    return DeviceInfo(
      device: device ?? this.device,
      name: name ?? this.name,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
      lastConnected: lastConnected ?? this.lastConnected,
      rssi: rssi ?? this.rssi,
      isPaired: isPaired ?? this.isPaired,
    );
  }

  String get signalIcon {
    final rssiValue = rssi;
    if (rssiValue == null) return '📡';
    if (rssiValue > -50) return '🟢';
    if (rssiValue > -70) return '🟡';
    return '🔴';
  }

  @override
  String toString() {
    return 'DeviceInfo(name: $name, address: $address, connected: $isConnected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}
