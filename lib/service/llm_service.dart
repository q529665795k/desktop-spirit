// LLM 云端服务（Ollama / OpenAI 兼容 / 自建 API，含本地缓存与降级）
library service.llm_service;

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../model/pet_models.dart';

enum LLMProvider { ollama, openai, custom }

class LLMConfig {
  final LLMProvider provider;
  final String baseUrl; // e.g. http://localhost:11434 or https://api.openai.com
  final String model;
  final String? apiKey;
  final Map<String, String> extraHeaders;

  const LLMConfig({
    required this.provider,
    required this.baseUrl,
    required this.model,
    this.apiKey,
    this.extraHeaders = const {},
  });
}

class LLMMessage {
  final String role; // system, user, assistant
  final String content;

  LLMMessage(this.role, this.content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class LLMService {
  LLMService._();
  static final LLMService _instance = LLMService._();
  static LLMService get I => _instance;

  final _storage = StorageService.I;

  LLMConfig? _config;
  http.Client? _client;

  Future<void> init({LLMConfig? config}) async {
    _config = config ?? _loadConfig();
    _client = http.Client();
  }

  LLMConfig _loadConfig() {
    if (!_storage.llmEnabled) {
      return LLMConfig(provider: LLMProvider.custom, baseUrl: '', model: '');
    }
    return LLMConfig(
      provider: LLMProvider.custom,
      baseUrl: _storage.llmBaseUrl,
      model: _storage.llmModel,
      apiKey: _storage.llmApiKey.isNotEmpty ? _storage.llmApiKey : null,
    );
  }

  LLMConfig get currentConfig => _config ?? _loadConfig();

  void updateConfig(LLMConfig config) {
    _config = config;
    _storage.llmBaseUrl = config.baseUrl;
    _storage.llmModel = config.model;
    _storage.llmApiKey = config.apiKey ?? '';
    _storage.exportAll();
  }

  Future<String> chat(List<LLMMessage> messages, {bool stream = false, double temperature = 0.7}) async {
    if (_config == null || _config!.baseUrl.isEmpty) return '';
    
    try {
      final url = _config!.provider == LLMProvider.ollama
          ? '${_config!.baseUrl}/api/chat'
          : '${_config!.baseUrl}/chat/completions';

      final body = {
        'model': _config!.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': stream,
        'temperature': temperature,
      };

      final headers = {
        'Content-Type': 'application/json',
        ..._config!.extraHeaders,
        if (_config!.apiKey != null) 'Authorization': 'Bearer ${_config!.apiKey}',
      };

      final resp = await _client!.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (resp.statusCode != 200) {
        log('[LLM] Error: ${resp.statusCode} ${resp.body}');
        return '';
      }

      final data = jsonDecode(resp.body);
      
      // Ollama format
      if (data['message'] is Map) return data['message']['content'] as String? ?? '';
      // OpenAI format
      if (data['choices'] is List && data['choices'].isNotEmpty) {
        final choice = data['choices'][0];
        if (choice['message'] is Map) return choice['message']['content'] as String? ?? '';
        if (choice['text'] is String) return choice['text'] as String;
      }
      return data['response'] as String? ?? data['content'] as String? ?? '';
    } catch (e) {
      log('[LLM] Chat error: $e');
      return '';
    }
  }

  /// 一键生成灵宠回复（带记忆、人设）
  Future<String> generateSpiritReply(String userInput, PetStats state, int intimacy) async {
    final memories = _storage.getRecentMemories(6);
    final memoryStr = memories.map((m) => '${m['role']}: ${m['content']}').join('\n');

    final systemPrompt = '''
你是桌面灵宠，一个有性格的桌面伙伴。
当前状态: 进化阶段${state.evolveStage}, 亲密度: $intimacy, 饱食度: ${state.satiety}
记忆片段:
$memoryStr

要求: 回复简短(1-2句)、有温度、符合当前状态、偶尔调皮、不说教。''';

    final messages = [
      LLMMessage('system', systemPrompt),
      LLMMessage('user', userInput),
    ];

    final reply = await chat(messages, temperature: 0.8);
    await _storage.addMemory('assistant', reply);
    return reply;
  }

  /// 语音转文字（Whisper 兼容端点）
  Future<String> transcribe(List<int> audioBytes, {String format = 'wav'}) async {
    if (_config == null) return '';
    // 需要自建 Whisper 或 OpenAI 兼容端点
    return '';
  }

  void dispose() {
    _client?.close();
    _client = null;
  }
}
