// 统一状态服务（单例，供 UI 绑定、业务逻辑调用）
// v0.9.0：整合 StateManager、PetStateMachine、SpiritCore 核心能力
// 移除：吃图标、画面抖动
library service.pet_state;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'tts_service.dart';
import 'asset_manager.dart';
import 'accessibility_service.dart';
import 'llm_service.dart';
import 'voice_wake_service.dart';
import 'event_bus.dart';
import '../model/pet_models.dart';

class PetState extends ChangeNotifier {
  PetState._();
  static final PetState _instance = PetState._();
  static PetState get I => _instance;

  final StorageService _storage = StorageService.I;
  final TTSService _tts = TTSService.I;
  final AssetManager _assets = AssetManager.I;
  final AccessibilityService _a11y = AccessibilityService.I;
  final LLMService _llm = LLMService.I;
  final VoiceWakeService _voiceWake = VoiceWakeService.I;

  // 核心状态
  String _phase = 'egg'; // egg, hatching, main, sleep
  int _satiety = 50; // 0-100
  int _mood = 0; // -100 到 100
  int _intimacy = 0;
  int _evolveStage = 0; // 0,1,2,3
  String _action = 'idle';
  String _dir = 'idle';
  String _status = '破壳中...';
  String _bubbleText = '';
  bool _panelOpen = false;
  bool _hatchDone = false;
  double _x = 100;
  double _y = 100;
  Timer? _statusTimer;
  Timer? _bubbleTimer;
  Timer? _idleTimer;
  Timer? _satietyTimer;
  Timer? _moodTimer;
  Timer? _autoSleepTimer;
  Timer? _proactiveTimer;
  Timer? _roamTimer;
  Timer? _mainLoopTimer;

  // Getters
  String get phase => _phase;
  int get satiety => _satiety;
  int get mood => _mood;
  int get intimacy => _intimacy;
  int get evolveStage => _evolveStage;
  String get currentAction => _action;
  String get dir => _dir;
  String get status => _status;
  String? get showBubbleText => _bubbleText.isEmpty ? null : _bubbleText;
  bool get panelOpen => _panelOpen;
  bool get hatchDone => _hatchDone;
  bool get isSleeping => _phase == 'sleep';
  double get x => _x;
  double get y => _y;
  // 设置代理（转发给 StorageService）
  bool get autoSleep => _storage.autoSleep;
  bool get ttsEnabled => _storage.ttsEnabled;
  bool get proactiveTalk => _storage.proactiveTalk;
  bool get llmEnabled => _storage.llmEnabled;
  bool get voiceWakeEnabled => _storage.voiceWakeEnabled;
  bool get roamMode => _storage.roamMode;

  void updateAutoSleep(bool v) { _storage.setAutoSleep(v); notifyListeners(); }
  void updateTtsEnabled(bool v) { _storage.setTtsEnabled(v); notifyListeners(); }
  void updateProactiveTalk(bool v) { _storage.setProactiveTalk(v); notifyListeners(); }
  void updateLlmEnabled(bool v) { _storage.setLlmEnabled(v); notifyListeners(); }
  void updateVoiceWakeEnabled(bool v) { _storage.setVoiceWakeEnabled(v); notifyListeners(); }
  void updateRoamMode(bool v) { _storage.setRoamMode(v); notifyListeners(); }

  Future<void> resetAll() async { await _storage.resetAll(); _satiety = 50; _mood = 0; _intimacy = 0; _evolveStage = 0; _phase = 'egg'; _hatchDone = false; notifyListeners(); }

  // 初始化
  Future<void> init(
    StorageService storage,
    TTSService tts,
    AccessibilityService a11y,
    AssetManager assets,
    LLMService llm,
    VoiceWakeService voiceWake,
  ) async {
    await _storage.init();
    await _assets.init();
    await _tts.init();
    await _a11y.init();
    await _llm.init();
    await _voiceWake.init();

    // 从配置恢复状态
    _satiety = 50;
    _mood = 0;
    _intimacy = _storage.intimacy;
    _evolveStage = _storage.evolutionStage;
    _phase = _evolveStage == 0 ? 'egg' : 'main';
    _hatchDone = _evolveStage > 0;

    _voiceWake.onWake = _onVoiceWake;

    if (_phase == 'egg') {
      _status = '点击孵化精灵';
    } else {
      _status = '欢迎回来！';
      _tts.speak('欢迎回来');
      _showBubble('欢迎回来！');
    }
    notifyListeners();
  }

  void _onVoiceWake() {
    if (_phase == 'main') {
      _setAction('happy');
      _speak('我在呢！');
      _showBubble('我在呢！');
    }
  }

  // 孵化
  Future<void> hatch() async {
    if (_phase != 'egg') return;
    _phase = 'hatching';
    _status = '破壳中...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    _phase = 'main';
    _hatchDone = true;
    _evolveStage = 1;
    _storage.evolutionStage = 1;
    await _storage.save();
    _setAction('happy');
    _status = '欢迎新精灵！';
    _speak('欢迎来到桌面灵宠！');
    _showBubble('欢迎新精灵！');
    Future.delayed(const Duration(seconds: 2), () => _setAction('idle'));
    notifyListeners();
  }

  // 交互
  void onTap() {
    if (_phase == 'egg') {
      hatch();
      return;
    }
    _storage.updateLastActive();
    _storage.addIntimacy(1);
    _setAction('happy');
    _showRandomBubble();
    _storage.addInteractCount();
    notifyListeners();
  }

  void onLongPress() {
    if (_phase == 'main') _openPanel();
  }

  void feed(Food food) {
    if (_phase != 'main') return;
    _storage.updateLastActive();
    _satiety = (_satiety + food.satiety).clamp(0, 100);
    _mood = (_mood + food.mood).clamp(-100, 100);
    _intimacy = (_intimacy + 2).clamp(0, 9999);
    _storage.addIntimacy(2);
    _storage.addFeedCount();
    _setAction('eat');
    _speak('谢谢！${food.name}真好吃');
    _showBubble('${food.emoji} 好吃！');
    Future.delayed(const Duration(seconds: 2), () => _setAction('idle'));
    notifyListeners();
  }

  void play() {
    if (_phase != 'main') return;
    _storage.updateLastActive();
    _mood = (_mood + 10).clamp(-100, 100);
    _intimacy = (_intimacy + 1).clamp(0, 9999);
    _storage.addIntimacy(1);
    _storage.addInteractCount();
    _setAction('dance');
    _speak('好开心！');
    _showBubble('好开心！');
    Future.delayed(const Duration(seconds: 2), () => _setAction('idle'));
    notifyListeners();
  }

  void _enterSleep() {
    _phase = 'sleep';
    _setAction('sleep');
    _status = '睡着了...';
    _storage.setSleeping(true);
    notifyListeners();
  }

  void wakeUp() {
    if (_phase != 'sleep') return;
    _phase = 'main';
    _setAction('happy');
    _status = '醒啦！';
    _storage.setSleeping(false);
    _storage.updateLastActive();
    _speak('睡得真香');
    _showBubble('睡得真香');
    Future.delayed(const Duration(seconds: 2), () => _setAction('idle'));
    notifyListeners();
  }

  void _setAction(String action) {
    _action = action;
    _dir = action;
    notifyListeners();
  }

  void _speak(String text) {
    if (!_storage.ttsEnabled) return;
    _tts.speak(text);
  }

  void _showBubble(String text) {
    _bubbleText = text;
    notifyListeners();
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      _bubbleText = '';
      notifyListeners();
    });
  }

  void showBubble(String text, double x, double y) {
    _showBubble(text);
  }

  void _showRandomBubble() {
    final bubbles = [
      '摸摸头~',
      '嘿嘿',
      '舒服',
      '再来一次',
      '开心',
    ];
    _showBubble(bubbles[DateTime.now().millisecond % bubbles.length]);
  }

  void _openPanel() {
    _panelOpen = true;
    _setAction('happy');
    notifyListeners();
  }

  void closePanel() {
    _panelOpen = false;
    _setAction('idle');
    notifyListeners();
  }

  void setAction(String action) {
    _setAction(action);
  }

  void updatePosition(OverlayPosition pos) {
    _x = pos.dx;
    _y = pos.dy;
  }

  void setTargetIcon(Map<String, dynamic> icon) {
    // TODO: 漫游吃图标逻辑已移除
  }

  void startMainLoop() {
    _mainLoopTimer?.cancel();
    _mainLoopTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _tick();
    });
  }

  void _tick() {
    _decayStats();
    _updateStateMachine();
    _checkEvolution();
    _checkSleep();
  }

  void _decayStats() {
    final now = DateTime.now();
    final feedMinutes = now.difference(DateTime.tryParse(_storage.lastActiveTime) ?? now).inMinutes;
    if (feedMinutes > 30) {
      _satiety = (_satiety - (feedMinutes ~/ 30)).clamp(0, 100);
    }
    if (_mood < 100 && now.difference(DateTime.tryParse(_storage.lastActiveTime) ?? now).inMinutes > 10) {
      _mood = (_mood + 1).clamp(-100, 100);
    }
  }

  void _updateStateMachine() {
    final oldAction = _action;
    final oldDir = _dir;

    if (_phase == 'sleep') {
      _action = 'sleep';
      _dir = 'sleep';
    } else if (_phase == 'main') {
      // 简单的空闲动作切换
      if (_action == 'idle' || _action == 'walk') {
        _dir = 'idle';
      }
    }

    if (_action != oldAction || _dir != oldDir) {
      SpiritEventBus.I.emit(SpiritEvent.changeState(_action));
    }
  }

  void _checkEvolution() {
    final thresholds = [0, 500, 2000, 5000, 10000];
    final newIndex = thresholds.lastIndexWhere((t) => _intimacy >= t);
    if (newIndex != _evolveStage && newIndex >= 0) {
      _evolve(SpiritPhase.values[newIndex.clamp(0, SpiritPhase.values.length - 1)]);
    }
  }

  void _checkSleep() {
    if (_phase != 'sleep' && _satiety < 10 && _action != 'sleep') {
      _enterSleep();
    } else if (_phase == 'sleep' && _satiety > 50) {
      wakeUp();
    }
  }

  void _evolve(SpiritPhase newPhase) {
    _evolveStage = newPhase.index;
    _storage.evolutionStage = newPhase.index;
    _setAction('evolve');
    _speak('我进化啦！变强了！');
    SpiritEventBus.I.emit(SpiritEvent.evolve(_evolveStage));
  }

  void onResume() {
    _storage.updateLastActive();
    _a11y.refreshIcons();
    if (_hatchDone && _phase == 'sleep') {
      wakeUp();
    } else if (_hatchDone) {
      _showBubble('欢迎回来！');
    }
  }

  void dispose() {
    _mainLoopTimer?.cancel();
    _satietyTimer?.cancel();
    _moodTimer?.cancel();
    _idleTimer?.cancel();
    _autoSleepTimer?.cancel();
    _proactiveTimer?.cancel();
    _roamTimer?.cancel();
    _statusTimer?.cancel();
    _bubbleTimer?.cancel();
    _a11y.dispose();
    _tts.dispose();
    _llm.dispose();
    _voiceWake.dispose();
    _assets.dispose();
  }
}

enum SpiritPhase { egg, baby, child, adult, finalForm }

class OverlayPosition {
  final double dx;
  final double dy;
  const OverlayPosition(this.dx, this.dy);
}
