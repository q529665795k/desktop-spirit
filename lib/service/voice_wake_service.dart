// 唤醒词 / 语音唤醒服务（离线 Porcupine / Vosk 兼容预留，默认用系统语音识别）
library service.voice_wake_service;

import 'dart:async';
import 'package:flutter/services.dart';

class VoiceWakeService {
  VoiceWakeService._();
  static final VoiceWakeService _instance = VoiceWakeService._();
  static VoiceWakeService get I => _instance;

  static const _channel = MethodChannel('com.desktop_spirit/voice_wake');

  bool _initialized = false;
  bool _listening = false;
  VoidCallback? onWake;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // 尝试初始化原生端（可选）
      await _channel.invokeMethod('init', {'language': 'zh-CN'});
    } catch (_) {
      // 原生未实现，降级为无操作
    }
    _initialized = true;
  }

  Future<void> startListening() async {
    if (!_initialized) await init();
    if (_listening) return;
    try {
      await _channel.invokeMethod('startListening');
      _listening = true;
    } catch (_) {
      // 忽略
    }
  }

  Future<void> stopListening() async {
    if (!_listening) return;
    try {
      await _channel.invokeMethod('stopListening');
    } catch (_) {}
    _listening = false;
  }

  /// 模拟唤醒（用于测试或按钮触发）
  void simulateWake() {
    onWake?.call();
  }

  void dispose() {
    stopListening();
    _initialized = false;
  }
}