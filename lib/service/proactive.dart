// 主动对话系统
library service.proactive;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'llm_service.dart';
import 'tts_service.dart';

class ProactiveTalker {
  static bool _running = false;
  static DateTime? _lastTalk;
  static final Random _random = Random();

  static const Map<String, List<String>> _topics = {
    'happy': [
      '今天天气真好呀！',
      '看到你开心我也跟着开心~',
      '要不我们出去走走？',
      '最近有什么好玩的事吗？',
    ],
    'neutral': [
      '工作/学习累了吗？',
      '喝杯水休息一下吧。',
      '想聊聊天吗？',
      '我在这儿陪着你呢。',
    ],
    'hungry': [
      '肚子饿啦…',
      '有好吃的分我一点嘛？',
      '喂食时间到！',
    ],
    'lonely': [
      '你好久没理我了…',
      '摸摸头？',
      '感觉有点孤单呢。',
    ],
  };

  static void start() {
    if (_running) return;
    _running = true;
    _scheduleNext();
  }

  static void stop() {
    _running = false;
  }

  static void _scheduleNext() {
    if (!_running) return;

    int baseMinutes = 30 + _random.nextInt(30);
    final state = PetState.I;

    if (state.satiety < 30) baseMinutes = (baseMinutes * 0.5).round();
    if (state.mood == PetMood.lonely) baseMinutes = (baseMinutes * 0.7).round();

    baseMinutes = baseMinutes.clamp(5, 120);

    Future.delayed(Duration(minutes: baseMinutes), () {
      if (_running) _tryTalk();
    });
  }

  static void _tryTalk() {
    final state = PetState.I;
    final config = ConfigService.I;

    if (!config.proactiveTalk) return;
    if (state.isSleeping) return;
    if (state.mood == PetMood.angry) return;

    if (_lastTalk != null && DateTime.now().difference(_lastTalk!).inMinutes < 10) {
      _scheduleNext();
      return;
    }

    final topic = _pickTopic(state.mood.name);
    if (topic != null) {
      _lastTalk = DateTime.now();
      _speakWithLLM(topic).catchError((_) => TTSService.I.speak(topic));
    }

    _scheduleNext();
  }

  static String? _pickTopic(String mood) {
    final list = _topics[mood] ?? _topics['neutral']!;
    if (list.isEmpty) return null;
    return list[_random.nextInt(list.length)];
  }

  static Future<void> _speakWithLLM(String prompt) async {
    if (!ConfigService.I.llmEnabled) {
      throw 'LLM disabled';
    }
    final reply = await LLMService.I.generateSpiritReply(
      prompt,
      PetState.I,
      ConfigService.I.intimacy,
    );
    if (reply.isNotEmpty) {
      await TTSService.I.speak(reply);
    } else {
      throw 'LLM empty';
    }
  }

  static void onUserInteraction() {
    _lastTalk = DateTime.now().subtract(const Duration(minutes: 5));
  }

  static bool get isRunning => _running;
}
