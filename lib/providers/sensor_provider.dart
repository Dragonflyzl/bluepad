import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sensor_service.dart';
import 'bluetooth_provider.dart';

/// 传感器状态类
class SensorState {
  final bool enabled;
  final bool isClutchPressed;

  SensorState({
    this.enabled = false,
    this.isClutchPressed = false,
  });

  SensorState copyWith({
    bool? enabled,
    bool? isClutchPressed,
  }) {
    return SensorState(
      enabled: enabled ?? this.enabled,
      isClutchPressed: isClutchPressed ?? this.isClutchPressed,
    );
  }
}

/// 传感器服务 Provider
final sensorServiceProvider = Provider<SensorService>((ref) {
  final service = SensorService();
  final bluetoothService = ref.watch(bluetoothServiceProvider);
  service.setBluetoothService(bluetoothService);
  ref.onDispose(() => service.dispose());
  return service;
});

/// 传感器状态 Provider
final sensorProvider = StateNotifierProvider<SensorNotifier, SensorState>((ref) {
  final service = ref.watch(sensorServiceProvider);
  return SensorNotifier(service);
});

class SensorNotifier extends StateNotifier<SensorState> {
  final SensorService _service;

  SensorNotifier(this._service) : super(SensorState());

  void toggle(bool value) {
    if (value) {
      _service.startListening();
    } else {
      _service.stopListening();
    }
    state = state.copyWith(enabled: value);
  }

  void setClutch(bool pressed) {
    _service.setClutch(pressed);
    state = state.copyWith(isClutchPressed: pressed);
  }
}
