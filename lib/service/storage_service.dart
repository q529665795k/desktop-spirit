// 统一存储服务（合并原 ConfigService 所有设置）
library service.storage_service;

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../model/pet_models.dart';
import 'event_bus.dart';
import 'llm_service.dart';

class StorageService {
  StorageService._();
  static final StorageService _instance = StorageService._();
  static StorageService get I => _instance;

  SharedPreferences? _prefs;
  bool _initialized = false;

  // === 基础设置 ===
  bool autoHide = true;
  double opacity = 1.0;
  double volume = 1.0;
  bool soundEnabled = true;
  bool hapticEnabled = true;
  bool edgeDock = true;
  bool clickThrough = false;

  // === TTS ===
  bool ttsEnabled = true;
  double ttsRate = 1.0;
  String ttsVoice = 'auto'; // auto, male, female

  // === 进阶 ===
  bool llmEnabled = false;
  String llmBaseUrl = 'https://api.openai.com/v1';
  String llmApiKey = '';
  String llmModel = 'gpt-4o-mini';
  bool proactiveTalk = false;
  bool roamMode = false;
  bool autoSleep = true;
  String petPersonality = 'friendly'; // friendly, playful, calm, tsundere
  bool customAvatarEnabled = false;
  bool voiceWakeEnabled = false;
  int interactionCooldownSec = 2;

  // === 进化/成长 ===
  int evolutionStage = 0; // 0=蛋, 1=幼体, 2=成体, 3=终极
  int intimacy = 0;
  int feedCount = 0;
  int interactCount = 0;

  // === 状态 ===
  bool isSleeping = false;
  String lastActiveTime = '';

  // === 宠物核心状态 ===
  int satiety = 50;
  int mood = 0;

  // === 同步/备份 ===
  String? syncProvider;
  String? syncConfigJson;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _load();
    _initialized = true;
  }

  void _load() {
    // 基础设置
    autoHide = _prefs?.getBool('autoHide') ?? true;
    opacity = _prefs?.getDouble('opacity') ?? 1.0;
    volume = _prefs?.getDouble('volume') ?? 1.0;
    soundEnabled = _prefs?.getBool('soundEnabled') ?? true;
    hapticEnabled = _prefs?.getBool('hapticEnabled') ?? true;
    edgeDock = _prefs?.getBool('edgeDock') ?? true;
    clickThrough = _prefs?.getBool('clickThrough') ?? false;

    // TTS
    ttsEnabled = _prefs?.getBool('ttsEnabled') ?? true;
    ttsRate = _prefs?.getDouble('ttsRate') ?? 1.0;
    ttsVoice = _prefs?.getString('ttsVoice') ?? 'auto';

    // 进阶
    llmEnabled = _prefs?.getBool('llmEnabled') ?? false;
    llmBaseUrl = _prefs?.getString('llmBaseUrl') ?? 'https://api.openai.com/v1';
    llmApiKey = _prefs?.getString('llmApiKey') ?? '';
    llmModel = _prefs?.getString('llmModel') ?? 'gpt-4o-mini';
    proactiveTalk = _prefs?.getBool('proactiveTalk') ?? false;
    roamMode = _prefs?.getBool('roamMode') ?? false;
    autoSleep = _prefs?.getBool('autoSleep') ?? true;
    petPersonality = _prefs?.getString('petPersonality') ?? 'friendly';
    customAvatarEnabled = _prefs?.getBool('customAvatarEnabled') ?? false;
    voiceWakeEnabled = _prefs?.getBool('voiceWakeEnabled') ?? false;
    interactionCooldownSec = _prefs?.getInt('interactionCooldownSec') ?? 2;

    // 进化/成长
    evolutionStage = _prefs?.getInt('evolutionStage') ?? 0;
    intimacy = _prefs?.getInt('intimacy') ?? 0;
    feedCount = _prefs?.getInt('feedCount') ?? 0;
    interactCount = _prefs?.getInt('interactCount') ?? 0;

    // 状态
    isSleeping = _prefs?.getBool('isSleeping') ?? false;
    lastActiveTime = _prefs?.getString('lastActiveTime') ?? '';

    // 宠物核心状态
    satiety = _prefs?.getInt('satiety') ?? 50;
    mood = _prefs?.getInt('mood') ?? 0;

    // 同步
    syncProvider = _prefs?.getString('syncProvider');
    syncConfigJson = _prefs?.getString('syncConfig');
  }

  Future<void> _save() async {
    await _prefs?.setBool('autoHide', autoHide);
    await _prefs?.setDouble('opacity', opacity);
    await _prefs?.setDouble('volume', volume);
    await _prefs?.setBool('soundEnabled', soundEnabled);
    await _prefs?.setBool('hapticEnabled', hapticEnabled);
    await _prefs?.setBool('edgeDock', edgeDock);
    await _prefs?.setBool('clickThrough', clickThrough);

    await _prefs?.setBool('ttsEnabled', ttsEnabled);
    await _prefs?.setDouble('ttsRate', ttsRate);
    await _prefs?.setString('ttsVoice', ttsVoice);

    await _prefs?.setBool('llmEnabled', llmEnabled);
    await _prefs?.setString('llmBaseUrl', llmBaseUrl);
    await _prefs?.setString('llmApiKey', llmApiKey);
    await _prefs?.setString('llmModel', llmModel);
    await _prefs?.setBool('proactiveTalk', proactiveTalk);
    await _prefs?.setBool('roamMode', roamMode);
    await _prefs?.setBool('autoSleep', autoSleep);
    await _prefs?.setString('petPersonality', petPersonality);
    await _prefs?.setBool('customAvatarEnabled', customAvatarEnabled);
    await _prefs?.setBool('voiceWakeEnabled', voiceWakeEnabled);
    await _prefs?.setInt('interactionCooldownSec', interactionCooldownSec);

    await _prefs?.setInt('evolutionStage', evolutionStage);
    await _prefs?.setInt('intimacy', intimacy);
    await _prefs?.setInt('feedCount', feedCount);
    await _prefs?.setInt('interactCount', interactCount);

    await _prefs?.setBool('isSleeping', isSleeping);
    await _prefs?.setString('lastActiveTime', lastActiveTime);

    await _prefs?.setInt('satiety', satiety);
    await _prefs?.setInt('mood', mood);

    if (syncProvider != null) await _prefs?.setString('syncProvider', syncProvider!);
    if (syncConfigJson != null) await _prefs?.setString('syncConfig', syncConfigJson!);
  }

  // === 便捷 setter ===
  Future<void> setAutoHide(bool v) async { autoHide = v; await _save(); }
  Future<void> setOpacity(double v) async { opacity = v.clamp(0.3, 1.0); await _save(); }
  Future<void> setVolume(double v) async { volume = v.clamp(0.0, 1.0); await _save(); }
  Future<void> setSoundEnabled(bool v) async { soundEnabled = v; await _save(); }
  Future<void> setHapticEnabled(bool v) async { hapticEnabled = v; await _save(); }
  Future<void> setEdgeDock(bool v) async { edgeDock = v; await _save(); }
  Future<void> setClickThrough(bool v) async { clickThrough = v; await _save(); }

  Future<void> setTtsEnabled(bool v) async { ttsEnabled = v; await _save(); }
  Future<void> setTtsRate(double v) async { ttsRate = v.clamp(0.5, 2.0); await _save(); }
  Future<void> setTtsVoice(String v) async { ttsVoice = v; await _save(); }

  Future<void> setLlmEnabled(bool v) async { llmEnabled = v; await _save(); LLMService.I.updateConfig(LLMService.I.currentConfig); }
  Future<void> setLlmBaseUrl(String v) async { llmBaseUrl = v; await _save(); }
  Future<void> setLlmApiKey(String v) async { llmApiKey = v; await _save(); }
  Future<void> setLlmModel(String v) async { llmModel = v; await _save(); }
  Future<void> setProactiveTalk(bool v) async { proactiveTalk = v; await _save(); LLMService.I.updateConfig(LLMService.I.currentConfig); }
  Future<void> setRoamMode(bool v) async { roamMode = v; await _save(); LLMService.I.updateConfig(LLMService.I.currentConfig); }
  Future<void> setPetPersonality(String v) async { petPersonality = v; await _save(); }
  Future<void> setCustomAvatarEnabled(bool v) async { customAvatarEnabled = v; await _save(); }
  Future<void> setVoiceWakeEnabled(bool v) async { voiceWakeEnabled = v; await _save(); }
  Future<void> setInteractionCooldownSec(int v) async { interactionCooldownSec = v.clamp(1, 60); await _save(); }

  Future<void> addIntimacy(int delta) async { 
    intimacy = (intimacy + delta).clamp(0, 9999); 
    await _save(); 
    await _checkEvolution(); 
  }
  Future<void> addFeedCount() async { feedCount++; await _save(); await _checkEvolution(); }
  Future<void> addInteractCount() async { interactCount++; await _save(); await _checkEvolution(); }
  Future<void> addSatiety(int delta) async { satiety = (satiety + delta).clamp(0, 100); await _save(); }
  Future<void> addMood(int delta) async { mood = (mood + delta).clamp(-100, 100); await _save(); }

  Future<void> _checkEvolution() async {
    int newStage = evolutionStage;
    if (evolutionStage == 0 && feedCount >= 3) newStage = 1;
    else if (evolutionStage == 1 && intimacy >= 50 && feedCount >= 10) newStage = 2;
    else if (evolutionStage == 2 && intimacy >= 200 && feedCount >= 30 && interactCount >= 50) newStage = 3;

    if (newStage != evolutionStage) {
      evolutionStage = newStage;
      await _save();
      SpiritEventBus.I.emit(SpiritEvent.evolve(newStage));
    }
  }

  Future<void> setSleeping(bool v) async { isSleeping = v; await _save(); }
  Future<void> setAutoSleep(bool v) async { autoSleep = v; await _save(); }
  Future<void> updateLastActive() async { lastActiveTime = DateTime.now().toIso8601String(); await _save(); }

  // === 同步配置 ===
  Future<void> setSyncConfig(String provider, Map<String, dynamic> config) async {
    syncProvider = provider;
    syncConfigJson = json.encode(config);
    await _save();
  }

  Map<String, dynamic>? getSyncConfig() {
    if (syncConfigJson == null) return null;
    try {
      return json.decode(syncConfigJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // === 重置 ===
  Future<void> resetAll() async {
    await _prefs?.clear();
    _load();
  }

  // === 每日奖励 ===
  Future<void> checkDailyReward() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final last = _prefs?.getString('lastActiveDate') ?? '';
    if (last != today) {
      await _prefs?.setString('lastActiveDate', today);
      addIntimacy(5); // 每日首次 +5 亲密度
    }
  }

  // === 自定义头像 ===
  String? _customAvatarPath;
  String? getCustomAvatar() => _customAvatarPath;
  Future<void> setCustomAvatar(String? path) async {
    _customAvatarPath = path;
    await _prefs?.setString('customAvatarPath', path ?? '');
  }

  // === 头像偏移 ===
  double _avatarOffsetX = 0;
  double _avatarOffsetY = 0;
  Offset getAvatarOffset() => Offset(_avatarOffsetX, _avatarOffsetY);
  Future<void> setAvatarOffset(Offset offset) async {
    _avatarOffsetX = offset.dx;
    _avatarOffsetY = offset.dy;
    await _prefs?.setDouble('avatarOffsetX', offset.dx);
    await _prefs?.setDouble('avatarOffsetY', offset.dy);
  }

  // === 导出/导入设置 ===
  Map<String, dynamic> exportSettings() {
    return {
      'autoHide': autoHide,
      'opacity': opacity,
      'volume': volume,
      'soundEnabled': soundEnabled,
      'hapticEnabled': hapticEnabled,
      'edgeDock': edgeDock,
      'clickThrough': clickThrough,
      'ttsEnabled': ttsEnabled,
      'ttsRate': ttsRate,
      'ttsVoice': ttsVoice,
      'llmEnabled': llmEnabled,
      'llmBaseUrl': llmBaseUrl,
      'llmApiKey': llmApiKey,
      'llmModel': llmModel,
      'proactiveTalk': proactiveTalk,
      'roamMode': roamMode,
      'autoSleep': autoSleep,
      'petPersonality': petPersonality,
      'customAvatarEnabled': customAvatarEnabled,
      'voiceWakeEnabled': voiceWakeEnabled,
      'interactionCooldownSec': interactionCooldownSec,
    };
  }

  Future<void> importSettings(Map<String, dynamic> data) async {
    autoHide = data['autoHide'] ?? true;
    opacity = (data['opacity'] ?? 1.0).toDouble();
    volume = (data['volume'] ?? 1.0).toDouble();
    soundEnabled = data['soundEnabled'] ?? true;
    hapticEnabled = data['hapticEnabled'] ?? true;
    edgeDock = data['edgeDock'] ?? true;
    clickThrough = data['clickThrough'] ?? false;
    ttsEnabled = data['ttsEnabled'] ?? true;
    ttsRate = (data['ttsRate'] ?? 1.0).toDouble();
    ttsVoice = data['ttsVoice'] ?? 'auto';
    llmEnabled = data['llmEnabled'] ?? false;
    llmBaseUrl = data['llmBaseUrl'] ?? 'https://api.openai.com/v1';
    llmApiKey = data['llmApiKey'] ?? '';
    llmModel = data['llmModel'] ?? 'gpt-4o-mini';
    proactiveTalk = data['proactiveTalk'] ?? false;
    roamMode = data['roamMode'] ?? false;
    autoSleep = data['autoSleep'] ?? true;
    petPersonality = data['petPersonality'] ?? 'friendly';
    customAvatarEnabled = data['customAvatarEnabled'] ?? false;
    voiceWakeEnabled = data['voiceWakeEnabled'] ?? false;
    interactionCooldownSec = data['interactionCooldownSec'] ?? 2;
    await _save();
  }

  // === 额外方法 ===
  Future<void> save() async => _save();

  dynamic getSetting(String key) {
    switch (key) {
      case 'autoHide': return autoHide;
      case 'opacity': return opacity;
      case 'volume': return volume;
      case 'soundEnabled': return soundEnabled;
      case 'hapticEnabled': return hapticEnabled;
      case 'edgeDock': return edgeDock;
      case 'clickThrough': return clickThrough;
      case 'ttsEnabled': return ttsEnabled;
      case 'ttsRate': return ttsRate;
      case 'ttsVoice': return ttsVoice;
      case 'llmEnabled': return llmEnabled;
      case 'llmBaseUrl': return llmBaseUrl;
      case 'llmApiKey': return llmApiKey;
      case 'llmModel': return llmModel;
      case 'proactiveTalk': return proactiveTalk;
      case 'roamMode': return roamMode;
      case 'autoSleep': return autoSleep;
      case 'petPersonality': return petPersonality;
      case 'customAvatarEnabled': return customAvatarEnabled;
      case 'voiceWakeEnabled': return voiceWakeEnabled;
      case 'interactionCooldownSec': return interactionCooldownSec;
      case 'evolutionStage': return evolutionStage;
      case 'intimacy': return intimacy;
      case 'feedCount': return feedCount;
      case 'interactCount': return interactCount;
      case 'isSleeping': return isSleeping;
      case 'lastActiveTime': return lastActiveTime;
      case 'satiety': return satiety;
      case 'mood': return mood;
      case 'syncProvider': return syncProvider;
      case 'syncConfigJson': return syncConfigJson;
      default: return null;
    }
  }

  Map<String, dynamic> getSettings() => exportSettings();

  /// 获取最近记忆
  List<Map<String, dynamic>> getRecentMemories(int count) {
    final all = _prefs?.getStringList('llm_memories') ?? [];
    return all.map((e) => Map<String, dynamic>.from(json.decode(e))).toList()
      ..retainWhere((e) => e['role'] == 'user' || e['role'] == 'assistant')
      ..sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0))
      ..length = count;
  }

  /// 添加记忆
  Future<void> addMemory(String role, String content) async {
    final list = _prefs?.getStringList('llm_memories') ?? [];
    list.add(json.encode({
      'role': role,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
    // 只保留最近 50 条
    if (list.length > 50) list.removeRange(0, list.length - 50);
    await _prefs?.setStringList('llm_memories', list);
  }
  Map<String, dynamic> exportAll() {
    return {
      ...exportSettings(),
      'evolutionStage': evolutionStage,
      'intimacy': intimacy,
      'feedCount': feedCount,
      'interactCount': interactCount,
      'isSleeping': isSleeping,
      'lastActiveTime': lastActiveTime,
      'satiety': satiety,
      'mood': mood,
      'syncProvider': syncProvider,
      'syncConfig': syncConfigJson,
      'customAvatarPath': _customAvatarPath,
      'avatarOffsetX': _avatarOffsetX,
      'avatarOffsetY': _avatarOffsetY,
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    await importSettings(data);
    evolutionStage = data['evolutionStage'] ?? 0;
    intimacy = data['intimacy'] ?? 0;
    feedCount = data['feedCount'] ?? 0;
    interactCount = data['interactCount'] ?? 0;
    isSleeping = data['isSleeping'] ?? false;
    lastActiveTime = data['lastActiveTime'] ?? '';
    satiety = data['satiety'] ?? 50;
    mood = data['mood'] ?? 0;
    syncProvider = data['syncProvider'];
    syncConfigJson = data['syncConfig'];
    _customAvatarPath = data['customAvatarPath'];
    _avatarOffsetX = (data['avatarOffsetX'] ?? 0).toDouble();
    _avatarOffsetY = (data['avatarOffsetY'] ?? 0).toDouble();
    await _save();
  }
}
