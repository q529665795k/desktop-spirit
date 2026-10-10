// 常量定义
library core.constants;

class AssetPaths {
  static const String base = 'assets';
  static const List<String> actions = [
    'idle', 'happy', 'hungry', 'angry', 'sleep', 'eat', 'dance', 'talk',
    'roll', 'evolve', 'egg', 'final', 'items',
  ];

  static String actionDir(String action) => '$base/$action';
  static String frame(String action, int index) => '$base/$action/${action}_${index.toString().padLeft(2, '0')}.png';

  static const Map<String, int> frameCounts = {
    'idle': 5,
    'happy': 3,
    'hungry': 3,
    'angry': 3,
    'sleep': 4,
    'eat': 5,
    'dance': 5,
    'talk': 3,
    'roll': 5,
    'evolve': 8,
    'egg': 3,
    'final': 5,
    'items': 6,
  };

  static const Map<String, int> fps = {
    'idle': 6,
    'happy': 6,
    'hungry': 6,
    'angry': 5,
    'sleep': 2,
    'eat': 6,
    'dance': 8,
    'talk': 5,
    'roll': 8,
    'evolve': 6,
    'egg': 2,
    'final': 6,
    'items': 6,
  };
}

class ConfigKeys {
  static const String autoHide = 'auto_hide';
  static const String showFps = 'show_fps';
  static const String enableSound = 'enable_sound';
  static const String ttsRate = 'tts_rate';
  static const String ttsPitch = 'tts_pitch';
  static const String ttsVolume = 'tts_volume';
  static const String language = 'language';
  static const String petName = 'pet_name';
  static const String petPersonality = 'pet_personality';
  static const String useCustomAssets = 'use_custom_assets';
  static const String customAssetDir = 'custom_asset_dir';
  static const String llmEnabled = 'llm_enabled';
  static const String llmApiKey = 'llm_api_key';
  static const String llmModel = 'llm_model';
  static const String llmBaseUrl = 'llm_base_url';
  static const String proactiveTalk = 'proactive_talk';
  static const String roamMode = 'roam_mode';
  static const String eatIcons = 'eat_icons';
}

class LLMDefaults {
  static const String defaultModel = 'llama-3.2-3b-instruct-q4_k_m.gguf';
  static const String defaultBaseUrl = 'http://localhost:8080';
}

class Timings {
  static const Duration hungerTick = Duration(minutes: 1);
  static const Duration proactiveMinInterval = Duration(minutes: 30);
  static const Duration proactiveMaxInterval = Duration(minutes: 60);
  static const Duration sleepRecovery = Duration(minutes: 5);
  static const int sleepSatietyGain = 10;
  static const double edgeThreshold = 30.0;
  static const double centerThreshold = 40.0;
}