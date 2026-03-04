/// 输入处理状态管理 Provider
/// 对应 Android: MainViewModel 中的触摸、键盘输入相关逻辑
///
/// 管理触控板手势、键盘状态、空中鼠标等输入相关状态

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_info.dart';
import '../utils/hid_report_builder.dart';

// ==================== 触控板状态 ====================

/// 触控板手势数据
class TouchpadState {
  final bool isDragging;
  final bool isScrolling;
  final bool isZooming;
  final int fingerCount;
  final double lastX;
  final double lastY;

  const TouchpadState({
    this.isDragging = false,
    this.isScrolling = false,
    this.isZooming = false,
    this.fingerCount = 0,
    this.lastX = 0,
    this.lastY = 0,
  });

  TouchpadState copyWith({
    bool? isDragging,
    bool? isScrolling,
    bool? isZooming,
    int? fingerCount,
    double? lastX,
    double? lastY,
  }) {
    return TouchpadState(
      isDragging: isDragging ?? this.isDragging,
      isScrolling: isScrolling ?? this.isScrolling,
      isZooming: isZooming ?? this.isZooming,
      fingerCount: fingerCount ?? this.fingerCount,
      lastX: lastX ?? this.lastX,
      lastY: lastY ?? this.lastY,
    );
  }
}

/// 触控板状态 Provider
final touchpadStateProvider = StateProvider<TouchpadState>((ref) {
  return const TouchpadState();
});

/// 待处理的鼠标移动数据
/// 对应 Android: pendingDx, pendingDy
final pendingMouseMoveProvider = StateProvider<Offset>((ref) => Offset.zero);

/// 待处理的滚动数据
/// 对应 Android: pendingScrollV, pendingScrollH
final pendingScrollProvider = StateProvider<Offset>((ref) => Offset.zero);

// ==================== 键盘状态 ====================

/// 键盘输入模式
/// 0=ABC, 1=123, 2=Sym, 3=Fn, 4=Nav
enum KeyboardMode { abc, numbers, symbols, function, navigation }

/// 键盘状态
class KeyboardState {
  final KeyboardMode mode;
  final bool isChineseMode;
  final bool isCapsLock;
  final bool showHistory;
  final int activeModifiers;
  final bool isModifierLocked;

  const KeyboardState({
    this.mode = KeyboardMode.abc,
    this.isChineseMode = false,
    this.isCapsLock = false,
    this.showHistory = false,
    this.activeModifiers = 0,
    this.isModifierLocked = false,
  });

  KeyboardState copyWith({
    KeyboardMode? mode,
    bool? isChineseMode,
    bool? isCapsLock,
    bool? showHistory,
    int? activeModifiers,
    bool? isModifierLocked,
  }) {
    return KeyboardState(
      mode: mode ?? this.mode,
      isChineseMode: isChineseMode ?? this.isChineseMode,
      isCapsLock: isCapsLock ?? this.isCapsLock,
      showHistory: showHistory ?? this.showHistory,
      activeModifiers: activeModifiers ?? this.activeModifiers,
      isModifierLocked: isModifierLocked ?? this.isModifierLocked,
    );
  }
}

/// 键盘状态 Provider
final keyboardStateProvider = StateNotifierProvider<KeyboardNotifier, KeyboardState>((ref) {
  return KeyboardNotifier();
});

class KeyboardNotifier extends StateNotifier<KeyboardState> {
  KeyboardNotifier() : super(const KeyboardState());

  void setMode(KeyboardMode mode) {
    state = state.copyWith(mode: mode);
  }

  void toggleChineseMode() {
    state = state.copyWith(isChineseMode: !state.isChineseMode);
  }

  void toggleCapsLock() {
    state = state.copyWith(isCapsLock: !state.isCapsLock);
  }

  void setShowHistory(bool show) {
    state = state.copyWith(showHistory: show);
  }

  void toggleModifier(int mask) {
    final newMods = (state.activeModifiers & mask) != 0
        ? state.activeModifiers & ~mask
        : state.activeModifiers | mask;
    state = state.copyWith(activeModifiers: newMods);
  }

  void setModifierLock(bool locked) {
    state = state.copyWith(isModifierLocked: locked);
  }

  void clearModifiers() {
    state = state.copyWith(activeModifiers: 0);
  }
}

// ==================== 空中鼠标状态 ====================

/// 空中鼠标状态
class AirMouseState {
  final bool isActive;
  final bool isClutchPressed;
  final DateTime? clickLockTime;

  const AirMouseState({
    this.isActive = false,
    this.isClutchPressed = false,
    this.clickLockTime,
  });

  AirMouseState copyWith({
    bool? isActive,
    bool? isClutchPressed,
    DateTime? clickLockTime,
  }) {
    return AirMouseState(
      isActive: isActive ?? this.isActive,
      isClutchPressed: isClutchPressed ?? this.isClutchPressed,
      clickLockTime: clickLockTime ?? this.clickLockTime,
    );
  }

  bool get isClickLocked {
    if (clickLockTime == null) return false;
    return DateTime.now().difference(clickLockTime!).inMilliseconds < 150;
  }
}

/// 空中鼠标状态 Provider
final airMouseStateProvider = StateNotifierProvider<AirMouseNotifier, AirMouseState>((ref) {
  return AirMouseNotifier();
});

class AirMouseNotifier extends StateNotifier<AirMouseState> {
  AirMouseNotifier() : super(const AirMouseState());

  void toggle() {
    state = state.copyWith(isActive: !state.isActive);
  }

  void setActive(bool active) {
    state = state.copyWith(isActive: active);
  }

  void setClutch(bool pressed) {
    state = state.copyWith(isClutchPressed: pressed);
  }

  void setClickLock() {
    state = state.copyWith(clickLockTime: DateTime.now());
  }
}

/// 传感器数据 Provider
final sensorDataProvider = StateProvider<SensorData>((ref) => SensorData.zero());

class SensorData {
  final List<double> gyro;
  final List<double> accel;

  const SensorData({
    required this.gyro,
    required this.accel,
  });

  factory SensorData.zero() {
    return const SensorData(
      gyro: [0, 0, 0],
      accel: [0, 0, 0],
    );
  }

  SensorData copyWith({
    List<double>? gyro,
    List<double>? accel,
  }) {
    return SensorData(
      gyro: gyro ?? this.gyro,
      accel: accel ?? this.accel,
    );
  }
}

// ==================== 输入历史 ====================

/// 输入历史 Provider
/// 对应 Android: commandHistory
final commandHistoryProvider = StateNotifierProvider<CommandHistoryNotifier, List<String>>((ref) {
  return CommandHistoryNotifier();
});

class CommandHistoryNotifier extends StateNotifier<List<String>> {
  static const int maxHistory = 20;

  CommandHistoryNotifier() : super([]);

  void add(String command) {
    if (command.isEmpty) return;

    // 移除重复项（如果存在）
    final newList = state.where((c) => c != command).toList();

    // 添加到开头
    newList.insert(0, command);

    // 限制最大数量
    if (newList.length > maxHistory) {
      newList.removeLast();
    }

    state = newList;
  }

  void clear() {
    state = [];
  }
}

// ==================== 辅助枚举 ====================

enum MouseButton { left, right, middle }
enum SwipeDirection { up, down, left, right }

// ==================== 输入操作 Provider ====================

/// 输入操作
final inputActionsProvider = Provider((ref) {
  return InputActions(ref);
});

class InputActions {
  final Ref _ref;

  InputActions(this._ref);

  /// 处理鼠标移动
  /// 对应 Android: MainViewModel.handleMouseMove()
  void handleMouseMove(double dx, double dy, {bool isDragging = false}) {
    // TODO: 累积移动量，通过定时器批量发送
  }

  /// 处理点击
  /// 对应 Android: MainViewModel.handleClick()
  Future<void> handleClick(MouseButton button) async {
    // TODO: 发送点击报告
  }

  /// 处理滚动
  /// 对应 Android: MainViewModel.handleScroll()
  void handleScroll(double vertical, double horizontal) {
    // TODO: 累积滚动量，批量发送
  }

  /// 输入字符
  /// 对应 Android: MainViewModel.typeCharacter()
  Future<void> typeCharacter(String char) async {
    // TODO: 转换 HID 键码并发送
  }

  /// 输入字符串
  /// 对应 Android: MainViewModel.sendString()
  Future<void> typeString(String text) async {
    // TODO: 逐字符发送
    _ref.read(commandHistoryProvider.notifier).add(text);
  }

  /// 发送快捷键
  /// 对应 Android: MainViewModel.sendShortcut()
  Future<void> sendShortcut(String id) async {
    // TODO: 获取快捷键配置并发送
  }

  /// 三指点击（中键）
  /// 对应 Android: MainViewModel.handleThreeFingerTap()
  Future<void> handleThreeFingerTap() async {
    // TODO: 发送中键点击
  }

  /// 三指滑动
  /// 对应 Android: MainViewModel.handleThreeFingerSwipe()
  Future<void> handleThreeFingerSwipe(SwipeDirection direction) async {
    // TODO: 根据方向发送 Mission Control 等快捷键
  }

  /// 开始缩放
  /// 对应 Android: MainViewModel.startZoom()
  void startZoom() {
    // TODO: 发送 Ctrl 按下
  }

  /// 更新缩放
  /// 对应 Android: MainViewModel.updateZoom()
  void updateZoom(double delta) {
    // TODO: 发送滚轮事件
  }

  /// 结束缩放
  /// 对应 Android: MainViewModel.endZoom()
  void endZoom() {
    // TODO: 发送 Ctrl 释放
  }

  /// 启动惯性滚动
  /// 对应 Android: MainViewModel.startInertia()
  void startInertia(double vx, double vy) {
    // TODO: 启动惯性动画
  }

  /// 停止惯性滚动
  /// 对应 Android: MainViewModel.stopInertia()
  void stopInertia() {
    // TODO: 停止惯性动画
  }
}
