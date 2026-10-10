// TTS 语音服务
library spirit_tts;

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';

class SpiritTts {
  SpiritTts._();
  static final SpiritTts _instance = SpiritTts._();
  static SpiritTts get I => _instance;

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _settingsApplied = false;
  String? _maleVoice;
  String? _femaleVoice;
  String _currentVoice = 'female';
  double _rate = PetConfig.defaultTtsRate;
  double _pitch = PetConfig.defaultTtsPitch;
  double _volume = PetConfig.defaultTtsVolume;

  // 串行队列
  final _queue = <_TtsTask>[];
  bool _processing = false;

  Future<void> init() async {
    if (_ready) return;
    await _configureEngine();
    _ready = true;
  }

  Future<void> _configureEngine() async {
    await _tts.setVolume(_volume);
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
    await _scanVoices();
    await _applyVoice();
    _settingsApplied = true;
  }

  Future<void> _scanVoices() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (final v in voices) {
          final name = (v is Map ? v['name'] : v.toString()).toLowerCase();
          if (_isMale(name) && _maleVoice == null) _maleVoice = v is Map ? v['name'] : v.toString();
          if (_isFemale(name) && _femaleVoice == null) _femaleVoice = v is Map ? v['name'] : v.toString();
        }
      }
    } catch (_) {}
  }

  bool _isMale(String name) => name.contains('male') || name.contains('男') || name.contains('#male') || name.contains('deep');
  bool _isFemale(String name) => name.contains('female') || name.contains('女') || name.contains('#female') || name.contains('xia');

  Future<void> _applyVoice() async {
    final voice = _currentVoice == 'male' ? _maleVoice : _femaleVoice;
    if (voice != null) {
      await _tts.setVoice({'name': voice, 'locale': 'zh-CN'});
    }
  }

  Future<void> applySettings() async {
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
    await _tts.setVolume(_volume);
    await _applyVoice();
    _settingsApplied = true;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PetConfig.prefsTtsRate, _rate);
    await prefs.setString(PetConfig.prefsTtsVoice, _currentVoice);
    await prefs.setDouble(PetConfig.prefsTtsPitch, _pitch);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _rate = prefs.getDouble(PetConfig.prefsTtsRate) ?? PetConfig.defaultTtsRate;
    _currentVoice = prefs.getString(PetConfig.prefsTtsVoice) ?? 'female';
    _pitch = prefs.getDouble(PetConfig.prefsTtsPitch) ?? PetConfig.defaultTtsPitch;
    await applySettings();
  }

  void setRate(double rate) {
    _rate = rate.clamp(0.3, 1.0);
  }

  void setPitch(double pitch) {
    _pitch = pitch.clamp(0.5, 2.0);
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  void setVoice(String gender) {
    if (gender == 'male' || gender == 'female') {
      _currentVoice = gender;
    }
  }

  double get rate => _rate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get currentVoice => _currentVoice;
  String? get maleVoice => _maleVoice;
  String? get femaleVoice => _femaleVoice;

  Future<void> speak(String text) async {
    if (!_ready) await init();
    if (text.trim().isEmpty) return;
    _enqueue(_TtsTask(text: text, isSpeak: true));
  }

  Future<void> stop() async {
    _queue.clear();
    await _tts.stop();
  }

  Future<void> _enqueue(_TtsTask task) async {
    _queue.add(task);
    if (!_processing) _processQueue();
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty) {
      _processing = false;
      return;
    }
    _processing = true;
    final task = _queue.removeAt(0);
    try {
      if (task.isSpeak) {
        await _tts.speak(task.text);
      }
    } catch (_) {}
    await _processQueue();
  }
}

class _TtsTask {
  final String text;
  final bool isSpeak;
  _TtsTask({required this.text, required this.isSpeak});
}