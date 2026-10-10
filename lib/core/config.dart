// 配置常量
library pet_config;

class PetConfig {
  // 基础
  static const String appName = '桌面灵宠';
  static const String version = '0.9.0';
  static const int buildNumber = 14;

  // 悬浮窗默认大小
  static const double defaultWinW = 200;
  static const double defaultWinH = 200;
  static const double miniWinW = 76;
  static const double miniWinH = 96;

  // 边缘吸附阈值
  static const double edgeThreshold = 30;
  static const double centerThreshold = 40;

  // 睡眠
  static const int sleepStartHour = 23;
  static const int sleepEndHour = 7;
  static const int sleepRecoveryPerMinute = 10;

  // 饥饿
  static const int hungerDecayPerMinute = 1;
  static const int maxSatiety = 200;

  // 成长经验阈值
  static const Map<int, int> stageExp = {
    0: 0,      // egg
    1: 0,      // baby
    2: 100,    // child
    3: 300,    // teen
    4: 600,    // adult
    5: 1000,   // final
  };

  // TTS
  static const double defaultTtsRate = 0.55;
  static const double defaultTtsPitch = 1.0;
  static const double defaultTtsVolume = 1.0;

  // 漫游
  static const int roamIntervalMin = 30000;      // 30s
  static const int roamIntervalMax = 120000;     // 2min
  static const double roamSpeed = 0.8;           // dp/ms

  // 互动冷却
  static const int interactCooldownMs = 1800000; // 30min

  // 无障碍
  static const String a11yPrefsName = 'spirit_a11y';
  static const String a11yIconsKey = 'desktop_spirit_icons';
  static const String a11yOnKey = 'desktop_spirit_a11y_on';

  // SharedPreferences keys
  static const String prefsOverlayX = 'overlay_x';
  static const String prefsOverlayY = 'overlay_y';
  static const String prefsAutoHide = 'auto_hide';
  static const String prefsOpacity = 'overlay_opacity';
  static const String prefsTtsRate = 'tts_rate';
  static const String prefsTtsVoice = 'tts_voice';
  static const String prefsTtsPitch = 'tts_pitch';
  static const String prefsRoamEnabled = 'roam_enabled';
  static const String prefsEatIconEnabled = 'eat_icon_enabled';
  static const String prefsCustomAvatar = 'custom_avatar_path';
  static const String prefsPetName = 'pet_name';
  static const String prefsFeedLog = 'feed_log';

  // 食物
  static const List<Map<String, dynamic>> foods = [
    {'emoji': '🍗', 'name': '鸡腿', 'satiety': 25, 'mood': 5},
    {'emoji': '🍎', 'name': '苹果', 'satiety': 15, 'mood': 3},
    {'emoji': '🍰', 'name': '蛋糕', 'satiety': 35, 'mood': 8},
    {'emoji': '🍪', 'name': '饼干', 'satiety': 10, 'mood': 2},
    {'emoji': '🥩', 'name': '牛排', 'satiety': 40, 'mood': 10},
    {'emoji': '🍯', 'name': '蜂蜜', 'satiety': 20, 'mood': 5},
    {'emoji': '🍓', 'name': '草莓', 'satiety': 12, 'mood': 3},
    {'emoji': '🍭', 'name': '棒棒糖', 'satiety': 8, 'mood': 2},
  ];

  // 动作帧数
  static const Map<String, int> frameCounts = {
    'idle': 5,
    'happy': 3,
    'hungry': 3,
    'angry': 3,
    'sleep': 4,
    'eat': 5,
    'dance': 5,
    'roll': 5,
    'talk': 3,
    'evolve': 8,
    'roam': 6,
    'eat_icon': 8,
  };

  // FPS
  static const Map<String, int> fps = {
    'idle': 6,
    'happy': 6,
    'hungry': 6,
    'angry': 5,
    'sleep': 4,
    'eat': 6,
    'dance': 8,
    'roll': 8,
    'talk': 5,
    'evolve': 6,
    'roam': 6,
    'eat_icon': 8,
  };
}