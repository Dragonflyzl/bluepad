import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'bluetooth_service.dart';

class SensorConfig {
  final double sensitivity;
  final bool enabled;
  final double smoothingFactor;
  final double deadZone;
  final bool invertX;
  final bool invertY;

  const SensorConfig({
    this.sensitivity = 2.0,
    this.enabled = false,
    this.smoothingFactor = 0.5,
    this.deadZone = 0.035, // 对应 SNAP_THRESHOLD
    this.invertX = false,
    this.invertY = false,
  });

  static const defaultConfig = SensorConfig();

  SensorConfig copyWith({
    double? sensitivity,
    bool? enabled,
    double? smoothingFactor,
    double? deadZone,
    bool? invertX,
    bool? invertY,
  }) {
    return SensorConfig(
      sensitivity: sensitivity ?? this.sensitivity,
      enabled: enabled ?? this.enabled,
      smoothingFactor: smoothingFactor ?? this.smoothingFactor,
      deadZone: deadZone ?? this.deadZone,
      invertX: invertX ?? this.invertX,
      invertY: invertY ?? this.invertY,
    );
  }
}

class SensorService {
  BluetoothService? _bluetoothService;
  SensorConfig _config = SensorConfig.defaultConfig;
  StreamSubscription? _gyroSubscription;
  StreamSubscription? _accelSubscription;
  
  // 累加器 (亚像素处理)
  double _accumX = 0;
  double _accumY = 0;
  
  // 最新加速度计数据，用于计算姿态权重
  AccelerometerEvent? _latestAccel;
  
  bool _isClutchPressed = false;
  DateTime? _lastTimestamp;

  void setBluetoothService(BluetoothService service) {
    _bluetoothService = service;
  }

  void updateConfig(SensorConfig config) {
    _config = config;
  }

  void setClutch(bool pressed) {
    _isClutchPressed = pressed;
    if (!pressed) {
      _accumX = 0;
      _accumY = 0;
    }
  }

  void startListening() {
    stopListening();
    
    // 监听加速度计，获取手机倾斜姿态
    _accelSubscription = accelerometerEventStream(samplingPeriod: const Duration(milliseconds: 20)).listen((event) {
      _latestAccel = event;
    });

    // 监听陀螺仪，进行核心数据积分
    _gyroSubscription = gyroscopeEventStream(samplingPeriod: const Duration(milliseconds: 10)).listen((event) {
      if (!_isClutchPressed || _bluetoothService == null || _latestAccel == null) return;

      final now = DateTime.now();
      if (_lastTimestamp == null) {
        _lastTimestamp = now;
        return;
      }
      
      final dt = now.difference(_lastTimestamp!).inMicroseconds / 1000000.0;
      _lastTimestamp = now;

      if (dt <= 0 || dt > 0.1) return;

      // --- 核心算法移植自 touch native-lib.cpp ---

      // 1. 姿势权重计算 (根据手机在 Y/Z 轴的重力分量决定左右移动由哪个轴角速度主导)
      final ay = _latestAccel!.y.abs();
      final az = _latestAccel!.z.abs();
      final totalWeight = ay + az;
      final ratioY = (totalWeight > 0) ? ay / totalWeight : 1.0;
      final ratioZ = (totalWeight > 0) ? az / totalWeight : 0.0;

      // 2. 轴映射与方向校正
      // 左右移动 (DX): 结合 Y 轴和 Z 轴角速度。当手机竖立时由 Y 轴主导，放平时由 Z 轴主导。
      // 手机在竖直状态下：-gy (手机向左转为正 gy，鼠标向左移为负 dx，故取负)
      // 手机在放平状态下：-gz (手机向左转为正 gz，鼠标向左移为负 dx，故取负)
      double rawDX = -(event.y * ratioY + event.z * ratioZ) * 1.2;
      
      // 上下移动 (DY): 使用 X 轴角速度 (手机向前倾/后仰)
      // 向前倾为正 gx，鼠标向上移为负 dy，故取负
      double rawDY = -event.x;

      // 3. 吸附感算法 (低速死区处理)
      if (rawDX.abs() < _config.deadZone) rawDX = 0;
      if (rawDY.abs() < _config.deadZone) rawDY = 0;

      // 4. 指数加速逻辑
      final speed = sqrt(rawDX * rawDX + rawDY * rawDY);
      final accelFactor = 1.0 + speed * 2.5;

      // 5. 映射到鼠标位移 (参考 C++ 的 1200 缩放系数)
      final moveX = rawDX * _config.sensitivity * accelFactor * 1200.0;
      final moveY = rawDY * _config.sensitivity * accelFactor * 1200.0;

      // 6. 亚像素累加与限制 (V_CAP = 120)
      _accumX += moveX * dt;
      _accumY += moveY * dt;

      int sendX = _accumX.truncate();
      int sendY = _accumY.truncate();

      // 限制单次发送位移范围在 [-127, 127]
      sendX = sendX.clamp(-120, 120);
      sendY = sendY.clamp(-120, 120);

      if (sendX != 0 || sendY != 0) {
        _bluetoothService!.sendMouseReport(dx: sendX, dy: sendY);
        _accumX -= sendX;
        _accumY -= sendY;
      }
    });
  }

  void stopListening() {
    _gyroSubscription?.cancel();
    _accelSubscription?.cancel();
    _gyroSubscription = null;
    _accelSubscription = null;
    _accumX = 0;
    _accumY = 0;
    _lastTimestamp = null;
  }

  void calibrate() {
    _accumX = 0;
    _accumY = 0;
  }

  void dispose() {
    stopListening();
  }
}
