/// 剪贴板服务
/// 实现系统剪贴板监控和自动同步
/// 对应 Android: ClipboardMonitor.kt

import 'dart:async';
import 'package:flutter/services.dart';

/// 剪贴板内容变化回调
typedef ClipboardChangeCallback = void Function(String content);

/// 剪贴板服务
class ClipboardService {
  static final ClipboardService _instance = ClipboardService._internal();
  factory ClipboardService() => _instance;
  ClipboardService._internal();

  /// 剪贴板内容变化流控制器
  final StreamController<String> _clipboardChangeController =
      StreamController<String>.broadcast();

  /// 剪贴板内容变化流
  Stream<String> get onClipboardChanged => _clipboardChangeController.stream;

  /// 定时器，用于定期检查剪贴板
  Timer? _monitorTimer;

  /// 上次读取的剪贴板内容
  String _lastContent = '';

  /// 是否正在监控
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  /// 检查间隔（毫秒）
  static const int _checkIntervalMs = 1000;

  /// 开始监控剪贴板变化
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // 立即检查一次
    _checkClipboard();

    // 定时检查
    _monitorTimer = Timer.periodic(
      const Duration(milliseconds: _checkIntervalMs),
      (_) => _checkClipboard(),
    );
  }

  /// 停止监控剪贴板变化
  void stopMonitoring() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// 检查剪贴板内容
  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;

      if (text != null && text.isNotEmpty && text != _lastContent) {
        _lastContent = text;
        _clipboardChangeController.add(text);
      }
    } catch (e) {
      print('Clipboard check error: $e');
    }
  }

  /// 读取当前剪贴板内容
  Future<String?> readClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      print('Read clipboard error: $e');
      return null;
    }
  }

  /// 写入内容到剪贴板
  Future<void> writeClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _lastContent = text;
    } catch (e) {
      print('Write clipboard error: $e');
    }
  }

  /// 清理资源
  void dispose() {
    stopMonitoring();
    _clipboardChangeController.close();
  }
}
