// 数据模型
library model.pet_models;

/// 食物
class Food {
  final String emoji;
  final String name;
  final int satiety;
  final int mood;

  const Food(this.emoji, this.name, this.satiety, this.mood);

  static const foods = [
    Food('🍎', '苹果', 15, 2),
    Food('🍗', '鸡腿', 30, 5),
    Food('🍰', '蛋糕', 25, 8),
    Food('🥩', '牛排', 35, 10),
    Food('🍪', '饼干', 10, 1),
    Food('🍭', '棒棒糖', 12, 3),
  ];

  static Food random() => foods[DateTime.now().millisecondsSinceEpoch % foods.length];
}

/// 互动类型
enum InteractionType {
  poke,      // 戳
  pet,       // 抚摸
  drag,      // 拖拽
  longPress, // 长按
}

/// 宠物心情
enum PetMood {
  unhappy(-100, '不开心'),
  neutral(0, '平静'),
  happy(50, '开心'),
  veryHappy(100, '非常开心');

  final int value;
  final String label;
  const PetMood(this.value, this.label);

  static PetMood fromValue(int v) {
    if (v <= -50) return PetMood.unhappy;
    if (v <= 25) return PetMood.neutral;
    if (v <= 75) return PetMood.happy;
    return PetMood.veryHappy;
  }
}

/// 进化阶段
enum EvolveStage {
  egg(0, '蛋'),
  baby(1, '幼年'),
  child(2, '成长'),
  adult(3, '成年'),
  finalForm(4, '最终形态');

  final int stageIndex;
  final String label;
  const EvolveStage(this.stageIndex, this.label);

  static EvolveStage fromIndex(int i) => EvolveStage.values.firstWhere((e) => e.stageIndex == i, orElse: () => EvolveStage.egg);
}

/// 动画方向
enum AnimDir {
  idle, angry, dance, eat, happy, hungry, roll, sleep, talk, walk, finalForm;
}

/// 宠物统计数据
class PetStats {
  final int feedCount;
  final int playCount;
  final int interactCount;
  final int evolveStage;
  final int intimacy;
  final int satiety;

  PetStats({
    required this.feedCount,
    required this.playCount,
    required this.interactCount,
    required this.evolveStage,
    required this.intimacy,
    required this.satiety,
  });

  Map<String, dynamic> toJson() => {
    'feedCount': feedCount,
    'playCount': playCount,
    'interactCount': interactCount,
    'evolveStage': evolveStage,
    'intimacy': intimacy,
    'satiety': satiety,
  };

  factory PetStats.fromJson(Map<String, dynamic> json) => PetStats(
    feedCount: json['feedCount'] ?? 0,
    playCount: json['playCount'] ?? 0,
    interactCount: json['interactCount'] ?? 0,
    evolveStage: json['evolveStage'] ?? 0,
    intimacy: json['intimacy'] ?? 0,
    satiety: json['satiety'] ?? 50,
  );
}