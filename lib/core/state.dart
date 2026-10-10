// 核心状态管理
library core.state;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SpiritPhase { egg, hatchling, child, teen, adult, finalForm }
enum SpiritMood { happy, normal, hungry, angry, sleep, lonely }

class SpiritState extends ChangeNotifier {
  SpiritState._();
  static final SpiritState _instance = SpiritState._();
  static SpiritState get I => _instance;

  // Keys
  static const String _kPhase = 'spirit_phase';
  static const String _kSatiety = 'spirit_satiety';
  static const String _kMood = 'spirit_mood';
  static const String _kExp = 'spirit_exp';
  static const String _kIntimacy = 'spirit_intimacy';
  static const String _kFeedCount = 'spirit_feed_count';
  static const String _kInteractCount = 'spirit_interact_count';
  static const String _kLastFeed = 'spirit_last_feed';
  static const String _kLastInteract = 'spirit_last_interact';
  static const String _kSleepStart = 'spirit_sleep_start';
  static const String _kCustomAvatar = 'spirit_custom_avatar';
  static const String _kName = 'spirit_name';
  static const String _kBirthTime = 'spirit_birth_time';

  // State
  SpiritPhase _phase = SpiritPhase.egg;
  int _satiety = 100;
  SpiritMood _mood = SpiritMood.normal;
  int _exp = 0;
  int _intimacy = 0;
  int _feedCount = 0;
  int _interactCount = 0;
  DateTime? _lastFeed;
  DateTime? _lastInteract;
  DateTime? _sleepStart;
  String? _customAvatarPath;
  String _name = '灵宠';
  DateTime _birthTime = DateTime.now();

  // Runtime
  bool _sleeping = false;
  bool _panelOpen = false;
  String? _currentAction;

  // Getters
  SpiritPhase get phase => _phase;
  int get satiety => _satiety;
  SpiritMood get mood => _mood;
  int get exp => _exp;
  int get intimacy => _intimacy;
  int get feedCount => _feedCount;
  int get interactCount => _interactCount;
  DateTime? get lastFeed => _lastFeed;
  DateTime? get lastInteract => _lastInteract;
  String? get customAvatarPath => _customAvatarPath;
  String get name => _name;
  DateTime get birthTime => _birthTime;
  bool get sleeping => _sleeping;
  bool get panelOpen => _panelOpen;
  String? get currentAction => _currentAction;

  // Computed
  int get expForNext {
    switch (_phase) {
      case SpiritPhase.egg: return 0;
      case SpiritPhase.hatchling: return 50;
      case SpiritPhase.child: return 150;
      case SpiritPhase.teen: return 400;
      case SpiritPhase.adult: return 800;
      case SpiritPhase.finalForm: return 999999;
    }
  }

  double get progress {
    int prev = 0;
    switch (_phase) {
      case SpiritPhase.egg: prev = 0; break;
      case SpiritPhase.hatchling: prev = 0; break;
      case SpiritPhase.child: prev = 50; break;
      case SpiritPhase.teen: prev = 150; break;
      case SpiritPhase.adult: prev = 400; break;
      case SpiritPhase.finalForm: prev = 800; break;
    }
    final next = expForNext;
    if (next <= prev) return 1.0;
    return ((_exp - prev) / (next - prev)).clamp(0.0, 1.0);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _phase = SpiritPhase.values[prefs.getInt(_kPhase) ?? 0];
    _satiety = prefs.getInt(_kSatiety) ?? 100;
    _mood = SpiritMood.values[prefs.getInt(_kMood) ?? 1];
    _exp = prefs.getInt(_kExp) ?? 0;
    _intimacy = prefs.getInt(_kIntimacy) ?? 0;
    _feedCount = prefs.getInt(_kFeedCount) ?? 0;
    _interactCount = prefs.getInt(_kInteractCount) ?? 0;
    _lastFeed = prefs.getString(_kLastFeed) != null ? DateTime.parse(prefs.getString(_kLastFeed)!) : null;
    _lastInteract = prefs.getString(_kLastInteract) != null ? DateTime.parse(prefs.getString(_kLastInteract)!) : null;
    _sleepStart = prefs.getString(_kSleepStart) != null ? DateTime.parse(prefs.getString(_kSleepStart)!) : null;
    _customAvatarPath = prefs.getString(_kCustomAvatar);
    _name = prefs.getString(_kName) ?? '灵宠';
    _birthTime = prefs.getString(_kBirthTime) != null ? DateTime.parse(prefs.getString(_kBirthTime)!) : DateTime.now();
    _sleeping = prefs.getBool('spirit_sleeping') ?? false;
    _clamp();
    notifyListeners();
  }

  void _clamp() {
    _satiety = _satiety.clamp(0, 200);
    _exp = _exp.clamp(0, 999999);
    _intimacy = _intimacy.clamp(0, 999999);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPhase, _phase.index);
    await prefs.setInt(_kSatiety, _satiety);
    await prefs.setInt(_kMood, _mood.index);
    await prefs.setInt(_kExp, _exp);
    await prefs.setInt(_kIntimacy, _intimacy);
    await prefs.setInt(_kFeedCount, _feedCount);
    await prefs.setInt(_kInteractCount, _interactCount);
    if (_lastFeed != null) await prefs.setString(_kLastFeed, _lastFeed!.toIso8601String());
    if (_lastInteract != null) await prefs.setString(_kLastInteract, _lastInteract!.toIso8601String());
    if (_sleepStart != null) await prefs.setString(_kSleepStart, _sleepStart!.toIso8601String());
    if (_customAvatarPath != null) await prefs.setString(_kCustomAvatar, _customAvatarPath!);
    await prefs.setString(_kName, _name);
    await prefs.setString(_kBirthTime, _birthTime.toIso8601String());
    await prefs.setBool('spirit_sleeping', _sleeping);
  }

  // Actions
  Future<void> feed(int satietyGain, {int expGain = 5, int intimacyGain = 10}) async {
    _satiety = (_satiety + satietyGain).clamp(0, 200);
    _exp += expGain;
    _intimacy = (_intimacy + intimacyGain).clamp(0, 999999);
    _feedCount++;
    _lastFeed = DateTime.now();
    _updateMood();
    _checkEvolve();
    await _save();
    notifyListeners();
  }

  Future<void> interact({int expGain = 5, int intimacyGain = 5, int satietyCost = 2}) async {
    _exp += expGain;
    _intimacy = (_intimacy + intimacyGain).clamp(0, 999999);
    _satiety = (_satiety - satietyCost).clamp(0, 200);
    _interactCount++;
    _lastInteract = DateTime.now();
    _updateMood();
    _checkEvolve();
    await _save();
    notifyListeners();
  }

  Future<void> startSleep() async {
    _sleeping = true;
    _sleepStart = DateTime.now();
    _mood = SpiritMood.sleep;
    await _save();
    notifyListeners();
  }

  Future<void> endSleep() async {
    _sleeping = false;
    _sleepStart = null;
    _satiety = (_satiety + 10).clamp(0, 200);
    _updateMood();
    await _save();
    notifyListeners();
  }

  Future<void> tickHunger() async {
    if (_sleeping) return;
    _satiety = (_satiety - 1).clamp(0, 200);
    _updateMood();
    await _save();
    notifyListeners();
  }

  void _updateMood() {
    if (_sleeping) {
      _mood = SpiritMood.sleep;
    } else if (_satiety >= 80) {
      _mood = SpiritMood.happy;
    } else if (_satiety >= 40) {
      _mood = SpiritMood.normal;
    } else if (_satiety >= 15) {
      _mood = SpiritMood.hungry;
    } else if (_intimacy < 20 && _feedCount == 0) {
      _mood = SpiritMood.lonely;
    } else {
      _mood = SpiritMood.angry;
    }
  }

  void _checkEvolve() {
    while (_phase != SpiritPhase.finalForm && _exp >= expForNext) {
      _phase = SpiritPhase.values[_phase.index + 1];
    }
  }

  Future<void> setCustomAvatar(String path) async {
    _customAvatarPath = path;
    await _save();
    notifyListeners();
  }

  Future<void> clearCustomAvatar() async {
    _customAvatarPath = null;
    await _save();
    notifyListeners();
  }

  Future<void> rename(String name) async {
    _name = name.trim().isEmpty ? '灵宠' : name.trim();
    await _save();
    notifyListeners();
  }

  void setPanelOpen(bool open) {
    _panelOpen = open;
    notifyListeners();
  }

  void setCurrentAction(String? action) {
    _currentAction = action;
    notifyListeners();
  }
}