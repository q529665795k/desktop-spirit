// TTS 语音服务（多语音、缓存、设置同步）
library service.tts_service;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';

class TTSService {
  TTSService._();
  static final TTSService _instance = TTSService._();
  static TTSService get I => _instance;

  final FlutterTts _tts = FlutterTts();
  final StorageService _storage = StorageService.I;
  bool _initialized = false;
  List<Map<String, dynamic>> _voices = [];
  String? _maleVoice;
  String? _femaleVoice;

  bool get isInitialized => _initialized;
  List<Map<String, dynamic>> get voices => List.unmodifiable(_voices);

  Future<void> init() async {
    if (_initialized) return;

    await _tts.setLanguage(_storage.getSetting('language') ?? 'zh-CN');
    await _tts.setVolume(_storage.getSetting('volume') ?? 0.8);
    await _tts.setSpeechRate(_storage.getSetting('ttsRate') ?? 1.0);
    await _scanVoices();

    _initialized = true;
  }

  Future<void> _scanVoices() async {
    try {
      final list = await _tts.getVoices as List?;
      if (list != null) {
        _voices = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _pickDefaultVoices();
      }
    } catch (e) {
      print('TTS voice scan error: $e');
    }
  }

  void _pickDefaultVoices() {
    for (final v in _voices) {
      final name = (v['name'] ?? '').toString().toLowerCase();
      final locale = (v['locale'] ?? '').toString().toLowerCase();
      if (_maleVoice == null && (name.contains('male') || locale.contains('male') || name.contains('男'))) {
        _maleVoice = v['name'] as String;
      }
      if (_femaleVoice == null && (name.contains('female') || locale.contains('female') || name.contains('女'))) {
        _femaleVoice = v['name'] as String;
      }
    }
    _maleVoice ??= _voices.isNotEmpty ? _voices.first['name'] as String : null;
    _femaleVoice ??= _maleVoice;
  }

  /// 统一播报入口
  Future<void> speak(String text, {String? voice, double? rate, double? volume}) async {
    if (!_initialized) await init();
    if (!_storage.getSetting<bool>('ttsEnabled') ?? true) return;
    if (text.trim().isEmpty) return;

    final settings = _storage.getSettings();
    await _tts.setVolume(volume ?? settings['volume'] as double? ?? 0.8);
    await _tts.setSpeechRate(rate ?? settings['ttsRate'] as double? ?? 1.0);
    await _tts.setLanguage(settings['language'] as String? ?? 'zh-CN');

    final voiceName = voice ?? (settings['ttsVoice'] == 'male' ? _maleVoice : _femaleVoice);
    if (voiceName != null) await _tts.setVoice({'name': voiceName, 'locale': 'zh-CN'});

    await _tts.speak(text);
  }

  Future<void> stop() async => _tts.stop();

  Future<void> applySettings() async {
    final s = _storage.getSettings();
    await _tts.setLanguage(s['language'] as String? ?? 'zh-CN');
    await _tts.setVolume(s['volume'] as double? ?? 0.8);
    await _tts.setSpeechRate(s['ttsRate'] as double? ?? 1.0);
  }

  String? getMaleVoice() => _maleVoice;
  String? getFemaleVoice() => _femaleVoice;

  void dispose() {
    _tts.stop();
  }
}