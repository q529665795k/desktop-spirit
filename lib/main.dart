import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 品牌署名
const String kBrand = '摸鱼基地出品';
const String kAppName = '桌面灵宠';
const String kVersion = 'v0.7.1';

/// 预置吐槽短句(第5步会接系统 TTS 语音)
const List<String> kTaunts = [
  '咕噜咕噜~',
  '主人理理我嘛',
  '好无聊啊…',
  '我快饿成纸片啦',
  '戳我干嘛!',
  '哼,不理你了',
  '再摸要秃了!',
  '今天也要元气满满!',
  '蛋壳有点痒…',
  '什么时候破壳呀',
  '你又在玩手机',
  '陪我玩会儿呗',
  '困了…ZZZ',
  '这颗蛋很贵哒',
  '小心点,别摔着我',
  '求求给点吃的',
  '在吗在吗在吗',
  '主人辛苦啦',
  '摸摸头~',
  '我要看外面的世界!',
];

/// 破壳后小精灵的台词(第3步新增)
const List<String> kSpiritTaunts = [
  '嘿嘿,我出来啦!',
  '主人,摸摸耳朵~',
  '银发狐耳,天下第一!',
  '今天想吃小鱼干!',
  '破壳的感觉真不错!',
  '外面世界好亮呀!',
  '别戳啦,痒!',
  '尾巴可软啦~',
  '我闻到了好吃的!',
  '陪我看会儿天空呗',
];

/// 食物定义(第4步)
class Food {
  const Food(this.emoji, this.name, this.satiety, this.mood);
  final String emoji;
  final String name;
  final int satiety;
  final int mood;
}

const List<Food> kFoods = [
  Food('🍎', '苹果', 25, 5),
  Food('🐟', '小鱼干', 35, 8),
  Food('🍬', '糖果', 15, 3),
];

/// TTS 语音吐槽(第5步,系统文字转语音,零素材)
class SpiritTts {
  static FlutterTts? _tts;
  static bool _ready = false;

  static Future<void> ensure() async {
    if (_tts != null) return;
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('zh-CN');
      await _tts!.setSpeechRate(0.5);
      await _tts!.setVolume(1.0);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static Future<void> speak(String text) async {
    await ensure();
    if (!_ready) return;
    try {
      await _tts!.stop();
      await _tts!.speak(text);
    } catch (_) {}
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DesktopSpiritApp());
}

/// 悬浮窗独立入口(0.5.x 要求:悬浮窗 UI 由 overlayMain 承载,showOverlay 不传 Widget)
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SpiritOverlay(),
    ),
  );
}

/// 灵宠阶段(蛋 / 小精灵),存 SharedPreferences
enum SpiritPhase { egg, spirit }

class SpiritStore {
  static const String _kPhase = 'spirit_phase';
  static const String _kHatchReadyAt = 'hatch_ready_at';

  /// 首次打开后 5 分钟才能破壳(孵化倒计时)
  static DateTime? hatchReadyAt;

  static Future<SpiritPhase> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kPhase);
    return s == 'spirit' ? SpiritPhase.spirit : SpiritPhase.egg;
  }

  static Future<void> save(SpiritPhase phase) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPhase, phase == SpiritPhase.spirit ? 'spirit' : 'egg');
  }

  /// 初始化孵化时间:首次打开记录 now+5 分钟,之后一直沿用
  static Future<void> ensureHatchTimer() async {
    if (hatchReadyAt != null) return;
    final p = await SharedPreferences.getInstance();
    final ts = p.getInt(_kHatchReadyAt);
    if (ts != null) {
      hatchReadyAt = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      hatchReadyAt = DateTime.now().add(const Duration(minutes: 5));
      await p.setInt(_kHatchReadyAt, hatchReadyAt!.millisecondsSinceEpoch);
    }
  }

  /// 距可破壳还有多少秒(0 表示可以破壳)
  static int remainingSeconds() {
    if (hatchReadyAt == null) return 0;
    final diff = hatchReadyAt!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }
}

/// 悬浮窗设置:透明度 / 自动贴边隐藏(SharedPreferences 持久化,主 App 与悬浮窗共用)
class SpiritConfig {
  static const String kOpacity = 'overlay_opacity';
  static const String kAutoHide = 'auto_hide_enabled';
  static const String kAutoHideDelay = 'auto_hide_delay';

  /// 悬浮窗透明度 0.4 ~ 1.0
  static double opacity = 1.0;

  /// 是否启用闲置自动贴边缩头
  static bool autoHide = true;

  /// 闲置多少秒后自动缩到角落(10~120)
  static int autoHideDelay = 20;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    opacity = (p.getDouble(kOpacity) ?? 1.0).clamp(0.4, 1.0);
    autoHide = p.getBool(kAutoHide) ?? true;
    autoHideDelay = p.getInt(kAutoHideDelay) ?? 20;
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(kOpacity, opacity);
    await p.setBool(kAutoHide, autoHide);
    await p.setInt(kAutoHideDelay, autoHideDelay);
  }
}

class DesktopSpiritApp extends StatelessWidget {
  const DesktopSpiritApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8E7CC3),
      ),
      home: const HomePage(),
    );
  }
}

/// 第4-6步共享状态:饱腹度/心情/喂食次数/进化/最后互动时间(SharedPreferences 持久化)
class SpiritState {
  static const String kSatiety = 'satiety';
  static const String kMood = 'mood';
  static const String kFeedCount = 'feed_count';
  static const String kEvo = 'evo';
  static const String kLastInteract = 'last_interact';

  static int satiety = 80;
  static int mood = 80;
  static int feedCount = 0;
  static bool evo = false;
  static DateTime lastInteract = DateTime.now();

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    satiety = p.getInt(kSatiety) ?? 80;
    mood = p.getInt(kMood) ?? 80;
    feedCount = p.getInt(kFeedCount) ?? 0;
    evo = p.getBool(kEvo) ?? false;
    final ts = p.getInt(kLastInteract);
    lastInteract = ts != null
        ? DateTime.fromMillisecondsSinceEpoch(ts)
        : DateTime.now();
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(kSatiety, satiety);
    await p.setInt(kMood, mood);
    await p.setInt(kFeedCount, feedCount);
    await p.setBool(kEvo, evo);
    await p.setInt(kLastInteract, lastInteract.millisecondsSinceEpoch);
  }

  static void touch() {
    lastInteract = DateTime.now();
  }

  /// 每 30 秒衰减 1 点
  static void decay() {
    if (satiety > 5) satiety--;
    if (mood > 10) mood--;
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _permission = false;
  bool _overlayVisible = false;
  String _status = '检查权限中…';
  SpiritPhase _phase = SpiritPhase.egg;
  bool _loaded = false;

  double _opacity = 1.0;
  bool _autoHide = true;
  int _autoHideDelay = 20;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadPhase();
    SpiritState.load().then((_) {
      if (mounted) setState(() {});
    });
    SpiritConfig.load().then((_) {
      if (!mounted) return;
      setState(() {
        _opacity = SpiritConfig.opacity;
        _autoHide = SpiritConfig.autoHide;
        _autoHideDelay = SpiritConfig.autoHideDelay;
      });
    });
  }

  Future<void> _loadPhase() async {
    // 首次打开:记录孵化倒计时(5 分钟),之后一直沿用
    await SpiritStore.ensureHatchTimer();
    final ph = await SpiritStore.load();
    if (!mounted) return;
    setState(() {
      _phase = ph;
      _loaded = true;
    });
  }

  Future<void> _checkPermission() async {
    final ok = await FlutterOverlayWindow.isPermissionGranted();
    if (!mounted) return;
    setState(() {
      _permission = ok;
      _status = ok ? '悬浮窗权限:已授权' : '悬浮窗权限:未授权';
    });
  }

  Future<void> _start() async {
    // 每次实查系统真实授权状态(MIUI 上 requestPermission 返回值不可信)
    var granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      await FlutterOverlayWindow.requestPermission();
      granted = await FlutterOverlayWindow.isPermissionGranted();
    }
    if (!granted) {
      if (!mounted) return;
      setState(() {
        _permission = false;
        _status = '未授权:请到 设置 → 应用 → 桌面灵宠 → 显示在其他应用上层 → 允许;小米记得把"后台弹出界面"也打开';
      });
      _showPermissionGuide();
      return;
    }
    if (!mounted) return;
    setState(() {
      _permission = true;
      _status = '悬浮窗权限:已授权';
    });
    await FlutterOverlayWindow.showOverlay(
      height: 240,
      width: 200,
      overlayTitle: kAppName,
      overlayContent: '灵宠悬浮窗',
      flag: OverlayFlag.defaultFlag,
      enableDrag: true,
      positionGravity: PositionGravity.auto,
    );
    if (!mounted) return;
    setState(() => _overlayVisible = true);
  }

  Future<void> _stop() async {
    await FlutterOverlayWindow.closeOverlay();
    if (!mounted) return;
    setState(() => _overlayVisible = false);
  }

  void _onHatchComplete() {
    setState(() => _phase = SpiritPhase.spirit);
    SpiritStore.save(SpiritPhase.spirit);
  }

  /// 破壳被 5 分钟倒计时拦下时提示剩余时间
  void _onHatchBlocked() {
    final sec = SpiritStore.remainingSeconds();
    final m = sec ~/ 60;
    final s = sec % 60;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏳ 蛋还在孵化中… ${m}分${s}秒后可破壳'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateOpacity(double v) async {
    SpiritConfig.opacity = v;
    await SpiritConfig.save();
    try {
      await FlutterOverlayWindow.shareData(jsonEncode({'opacity': v}));
    } catch (_) {}
    if (!mounted) return;
    setState(() => _opacity = v);
  }

  Future<void> _updateAutoHide(bool v) async {
    SpiritConfig.autoHide = v;
    await SpiritConfig.save();
    if (!mounted) return;
    setState(() => _autoHide = v);
  }

  Future<void> _updateAutoHideDelay(double v) async {
    SpiritConfig.autoHideDelay = v.round();
    await SpiritConfig.save();
    if (!mounted) return;
    setState(() => _autoHideDelay = v.round());
  }

  Widget _buildStats() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🍽️ 饱腹度 ${SpiritState.satiety}/100', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 10),
            Text('😊 心情 ${SpiritState.mood}/100', style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        if (SpiritState.evo)
          const Text('✨ 已进化完全体', style: TextStyle(fontSize: 12, color: Color(0xFFB8860B)))
        else
          Text('进化进度:喂食 ${SpiritState.feedCount}/10 次', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFoodRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final f in kFoods)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton.tonal(
              onPressed: () => _feedFromHome(f),
              child: Text('${f.emoji} ${f.name}'),
            ),
          ),
      ],
    );
  }

  Future<void> _feedFromHome(Food food) async {
    SpiritState.touch();
    SpiritState.satiety = math.min(100, SpiritState.satiety + food.satiety);
    SpiritState.mood = math.min(100, SpiritState.mood + food.mood);
    SpiritState.feedCount++;
    await SpiritState.save();
    if (!mounted) return;
    setState(() {});
    SpiritTts.speak('${food.name}好好吃呀,谢谢主人');
    if (!SpiritState.evo && SpiritState.feedCount >= 10) {
      setState(() => SpiritState.evo = true);
      await SpiritState.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ 进化啦!完全体形态 ✨')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('喂了${food.name},饱腹度+${food.satiety}'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _showPermissionGuide() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('悬浮窗权限还没开'),
        content: const Text(
          '小米/红米手机:设置 → 应用设置 → 应用管理 → 桌面灵宠 → 权限管理 → 显示在其他应用上层 → 允许;'
          '同时打开「后台弹出界面」,否则悬浮窗开不起来。\n\n授权后回来再点一次「开始悬浮窗」就行。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
        ],
      ),
    );
  }


  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$kAppName · $kVersion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFDF6FF), Color(0xFFC9B8F5)],
                ),
              ),
              alignment: Alignment.center,
              child: const Text('🦊', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            const Text('一颗蛋破壳,变成银发狐耳少女灵宠'),
            const SizedBox(height: 8),
            Text(
              kBrand,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text('一只蛋,一颗心,一个爱捣鼓的普通人做的', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            const Text('白天工地搬砖,晚上自学写代码,纯个人爱好', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            const Text('初中文化,没上过培训班,全靠自己折腾', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            const Text('一台手机+云电脑+GitHub,零成本做出这个小东西', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            const Text('纯原创 · 自用 · 不上架 · 不商用', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('开发:Marvis 云端 + GitHub Actions', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 灵宠形象(蛋或小精灵,点击破壳)
              SpiritAvatar(
                phase: _phase,
                size: 150,
                onHatchComplete: _onHatchComplete,
                onHatchBlocked: _onHatchBlocked,
              ),
              const SizedBox(height: 16),
              Text(kAppName, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                _phase == SpiritPhase.egg ? '一颗蛋正在孵化中…' : '小狐耳已经破壳啦!',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copyright, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(kBrand, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 20),
              Text(_status, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              _buildStats(),
              const SizedBox(height: 8),
              _buildFoodRow(),
              const SizedBox(height: 16),
              // v0.7.0:悬浮窗设置(透明化 + 自动贴边)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('悬浮窗设置', style: theme.textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('透明化', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Slider(
                              value: _opacity,
                              min: 0.4,
                              max: 1.0,
                              divisions: 12,
                              label: '${(_opacity * 100).round()}%',
                              onChanged: (v) => _updateOpacity(v),
                            ),
                          ),
                          Text('${(_opacity * 100).round()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('闲置自动贴边缩头', style: TextStyle(fontSize: 13)),
                          const Spacer(),
                          Switch(
                            value: _autoHide,
                            onChanged: _updateAutoHide,
                          ),
                        ],
                      ),
                      if (_autoHide) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text('延时', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: _autoHideDelay.toDouble(),
                                min: 10,
                                max: 120,
                                divisions: 22,
                                label: '$_autoHideDelay 秒',
                                onChanged: (v) => _updateAutoHideDelay(v),
                              ),
                            ),
                            Text('$_autoHideDelay 秒', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.pets),
                label: Text(_overlayVisible ? '悬浮窗已开启,再次点击' : '开始悬浮窗'),
              ),
              if (_overlayVisible) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: _stop, child: const Text('关闭悬浮窗')),
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showAbout,
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('关于 · 摸鱼基地出品'),
              ),
              const SizedBox(height: 16),
              Text(
                '小提示:悬浮窗开启后回桌面就能看到灵宠,可拖动;闲置会自动缩到左上角露小头,点一下恢复。'
                'v0.7.1 交互:单击灵宠=摸头,双击=戳肚子吐槽,长按=呼出喂食/隐藏面板。',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 灵宠形象:蛋(点击可破壳) / 小精灵(待机呼吸眨眼)
/// 悬浮窗和主页共用,素材到位后替换为豆包序列帧
class SpiritAvatar extends StatefulWidget {
  const SpiritAvatar({
    super.key,
    required this.phase,
    this.size = 150,
    this.onHatchComplete,
    this.onHatchBlocked,
    this.evo = false,
    this.sleep = false,
  });

  final SpiritPhase phase;
  final double size;
  final VoidCallback? onHatchComplete;

  /// 点击破壳但 5 分钟孵化倒计时未到
  final VoidCallback? onHatchBlocked;
  final bool evo;
  final bool sleep;

  @override
  State<SpiritAvatar> createState() => _SpiritAvatarState();
}

class _SpiritAvatarState extends State<SpiritAvatar>
    with SingleTickerProviderStateMixin {
  bool _hatching = false;
  bool _justHatched = false;

  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final AnimationController _hatch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void dispose() {
    _idle.dispose();
    _hatch.dispose();
    super.dispose();
  }

  void _startHatch() {
    if (_hatching) return;
    // 5 分钟孵化倒计时未到:不给破壳,通知上层提示
    final remain = SpiritStore.remainingSeconds();
    if (remain > 0) {
      widget.onHatchBlocked?.call();
      return;
    }
    setState(() => _hatching = true);
    _hatch.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _hatching = false;
        _justHatched = true;
      });
      widget.onHatchComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final isSpirit = widget.phase == SpiritPhase.spirit;

    if (isSpirit || _justHatched) {
      // 小精灵形态:呼吸 + 眨眼
      return AnimatedBuilder(
        animation: _idle,
        builder: (context, child) {
          final t = _idle.value;
          final blink = math.sin(t * math.pi * 2) > 0.92 ? 0.0 : 1.0;
          return Transform.translate(
            offset: Offset(0, -t * 6),
            child: Transform.scale(
              scale: 1 + t * 0.02,
              child: SizedBox(
                width: s,
                height: s * 1.15,
                child: CustomPaint(painter: _SpiritPainter(blink: widget.sleep ? 0 : blink, isEvo: widget.evo)),
              ),
            ),
          );
        },
      );
    }

    if (_hatching) {
      // 破壳动画:蛋震 → 裂纹 → 闪光 → 蹦出小精灵
      return AnimatedBuilder(
        animation: _hatch,
        builder: (context, child) {
          final t = _hatch.value;
          final shake = t < 0.3 ? math.sin(t * 60) * 6 * (1 - t) : 0.0;
          final crack = t < 0.4 ? (t / 0.4).clamp(0.0, 1.0) : 1.0;
          final flash = t >= 0.35 && t <= 0.55
              ? (1 - (t - 0.35) / 0.2).clamp(0.0, 1.0)
              : 0.0;
          final pop = t >= 0.55 ? ((t - 0.55) / 0.3).clamp(0.0, 1.0) : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 闪光
              if (flash > 0)
                Container(
                  width: s * 1.6,
                  height: s * 1.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(flash * 0.9),
                  ),
                ),
              // 蛋
              Transform.translate(
                offset: Offset(shake, 0),
                child: SizedBox(
                  width: s,
                  height: s * 1.15,
                  child: CustomPaint(
                    painter: _EggPainter(crack: crack.toDouble()),
                  ),
                ),
              ),
              // 蹦出的小精灵
              if (pop > 0)
                Transform.translate(
                  offset: Offset(0, s * 0.5 * (1 - pop)),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * pop,
                    child: SizedBox(
                      width: s,
                      height: s * 1.15,
                      child: CustomPaint(painter: _SpiritPainter(blink: 1.0, isEvo: widget.evo)),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    // 蛋形态:呼吸浮动 + 点击破壳
    return GestureDetector(
      onTap: _startHatch,
      child: AnimatedBuilder(
        animation: _idle,
        builder: (context, child) {
          final t = _idle.value;
          return Transform.translate(
            offset: Offset(0, -t * 10),
            child: Transform.scale(scale: 1 + t * 0.04, child: child),
          );
        },
        child: SizedBox(
          width: s,
          height: s * 1.15,
          child: CustomPaint(painter: _EggPainter(crack: 0)),
        ),
      ),
    );
  }
}

/// 蛋的绘制:渐变蛋体 + 裂纹
class _EggPainter extends CustomPainter {
  const _EggPainter({required this.crack});
  final double crack;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final eggRect = Rect.fromCenter(center: center, width: w * 0.78, height: h * 0.9);
    final eggPath = Path()
      ..addOval(eggRect)
      ..close();

    // 蛋体渐变
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFDF6FF), Color(0xFFC9B8F5), Color(0xFF9C8ADF)],
      ).createShader(eggRect);
    canvas.drawPath(eggPath, paint);

    // 高光
    final shine = Paint()..color = const Color(0x66FFFFFF);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - w * 0.18, center.dy - h * 0.2),
        width: w * 0.22,
        height: h * 0.12,
      ),
      shine,
    );

    // 裂纹(破壳时)
    if (crack > 0) {
      final line = Paint()
        ..color = const Color(0xFF5B4A8F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      final path = Path();
      final n = 6;
      for (var i = 0; i <= n; i++) {
        final x = center.dx + (i - n / 2) * (w * 0.12);
        final y = center.dy + math.sin(i * 1.3) * h * 0.16 * crack + (i - n / 2) * h * 0.05 * crack;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant _EggPainter old) => old.crack != crack;
}

/// 小精灵占位绘制:银发狐耳少女(呼吸眨眼)
class _SpiritPainter extends CustomPainter {
  const _SpiritPainter({required this.blink, this.isEvo = false});
  final double blink; // 1=睁眼 0=闭眼
  final bool isEvo; // 完全体:金色光环+翅膀

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + h * 0.05;

    // 完全体装饰:金色光环 + 双翼(进化后)
    if (isEvo) {
      final halo = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy - h * 0.32),
          width: w * 0.52,
          height: h * 0.26,
        ),
        halo,
      );
      final wingL = Paint()..color = const Color(0xFF9C8ADF);
      final wingPathL = Path()
        ..moveTo(cx - w * 0.30, cy + h * 0.12)
        ..quadraticBezierTo(cx - w * 0.52, cy - h * 0.02, cx - w * 0.40, cy - h * 0.16)
        ..quadraticBezierTo(cx - w * 0.28, cy - h * 0.02, cx - w * 0.24, cy + h * 0.05)
        ..close();
      canvas.drawPath(wingPathL, wingL);
      final wingR = Path()
        ..moveTo(cx + w * 0.30, cy + h * 0.12)
        ..quadraticBezierTo(cx + w * 0.52, cy - h * 0.02, cx + w * 0.40, cy - h * 0.16)
        ..quadraticBezierTo(cx + w * 0.28, cy - h * 0.02, cx + w * 0.24, cy + h * 0.05)
        ..close();
      canvas.drawPath(wingR, wingL);
    }

    // 尾巴(身后)
    final tail = Paint()..color = const Color(0xFFC9B8F5);
    final tailRect = Rect.fromCenter(
      center: Offset(cx - w * 0.30, cy + h * 0.10),
      width: w * 0.36,
      height: w * 0.30,
    );
    canvas.drawOval(tailRect, tail);

    // 身体(圆角方形,紫白渐变)
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy + h * 0.18),
      width: w * 0.68,
      height: h * 0.62,
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF6FB), Color(0xFFE8DFF7)],
      ).createShader(bodyRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.2)),
      bodyPaint,
    );

    // 头(圆)
    final headCenter = Offset(cx, cy - h * 0.10);
    final headRadius = w * 0.28;
    canvas.drawCircle(headCenter, headRadius, Paint()..color = const Color(0xFFFFF6FB));

    // 狐耳(左)
    final earLeft = Path()
      ..moveTo(headCenter.dx - w * 0.20, headCenter.dy - headRadius * 0.55)
      ..lineTo(headCenter.dx - w * 0.16, headCenter.dy - headRadius * 1.55)
      ..lineTo(headCenter.dx - w * 0.02, headCenter.dy - headRadius * 0.95)
      ..close();
    canvas.drawPath(earLeft, Paint()..color = const Color(0xFFC9B8F5));
    final earLeftIn = Path()
      ..moveTo(headCenter.dx - w * 0.18, headCenter.dy - headRadius * 0.62)
      ..lineTo(headCenter.dx - w * 0.155, headCenter.dy - headRadius * 1.35)
      ..lineTo(headCenter.dx - w * 0.07, headCenter.dy - headRadius * 0.92)
      ..close();
    canvas.drawPath(earLeftIn, Paint()..color = const Color(0xFFF7C8DC));

    // 狐耳(右)
    final earRight = Path()
      ..moveTo(headCenter.dx + w * 0.20, headCenter.dy - headRadius * 0.55)
      ..lineTo(headCenter.dx + w * 0.16, headCenter.dy - headRadius * 1.55)
      ..lineTo(headCenter.dx + w * 0.02, headCenter.dy - headRadius * 0.95)
      ..close();
    canvas.drawPath(earRight, Paint()..color = const Color(0xFFC9B8F5));
    final earRightIn = Path()
      ..moveTo(headCenter.dx + w * 0.18, headCenter.dy - headRadius * 0.62)
      ..lineTo(headCenter.dx + w * 0.155, headCenter.dy - headRadius * 1.35)
      ..lineTo(headCenter.dx + w * 0.07, headCenter.dy - headRadius * 0.92)
      ..close();
    canvas.drawPath(earRightIn, Paint()..color = const Color(0xFFF7C8DC));

    // 呆毛(头顶)
    final hair = Paint()
      ..color = const Color(0xFFB8A6E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final hairPath = Path()
      ..moveTo(headCenter.dx - w * 0.04, headCenter.dy - headRadius * 1.05)
      ..quadraticBezierTo(
        headCenter.dx + w * 0.06,
        headCenter.dy - headRadius * 1.35,
        headCenter.dx + w * 0.12,
        headCenter.dy - headRadius * 1.15,
      );
    canvas.drawPath(hairPath, hair);

    // 眼睛
    final eyeColor = Paint()..color = const Color(0xFF5B3E8F);
    final eyeDx = w * 0.14;
    final eyeDy = headCenter.dy + headRadius * 0.1;
    if (blink > 0.5) {
      canvas.drawCircle(Offset(headCenter.dx - eyeDx, eyeDy), w * 0.045, eyeColor);
      canvas.drawCircle(Offset(headCenter.dx + eyeDx, eyeDy), w * 0.045, eyeColor);
      // 高光
      final glint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(headCenter.dx - eyeDx - w * 0.015, eyeDy - w * 0.015), w * 0.016, glint);
      canvas.drawCircle(Offset(headCenter.dx + eyeDx - w * 0.015, eyeDy - w * 0.015), w * 0.016, glint);
    } else {
      canvas.drawLine(
        Offset(headCenter.dx - eyeDx - w * 0.04, eyeDy),
        Offset(headCenter.dx - eyeDx + w * 0.04, eyeDy),
        Paint()
          ..color = const Color(0xFF5B3E8F)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(headCenter.dx + eyeDx - w * 0.04, eyeDy),
        Offset(headCenter.dx + eyeDx + w * 0.04, eyeDy),
        Paint()
          ..color = const Color(0xFF5B3E8F)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // 腮红
    final blush = Paint()..color = const Color(0x66F49BAB);
    canvas.drawCircle(Offset(headCenter.dx - w * 0.22, headCenter.dy + headRadius * 0.30), w * 0.05, blush);
    canvas.drawCircle(Offset(headCenter.dx + w * 0.22, headCenter.dy + headRadius * 0.30), w * 0.05, blush);

    // 微笑
    final smile = Paint()
      ..color = const Color(0xFF8A6BBF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(headCenter.dx - w * 0.07, headCenter.dy + headRadius * 0.32)
      ..quadraticBezierTo(
        headCenter.dx,
        headCenter.dy + headRadius * 0.46,
        headCenter.dx + w * 0.07,
        headCenter.dy + headRadius * 0.32,
      );
    canvas.drawPath(smilePath, smile);
  }

  @override
  bool shouldRepaint(covariant _SpiritPainter old) =>
      old.blink != blink || old.isEvo != isEvo;
}

/// 悬浮窗:蛋/小精灵 + 喂食/摸头/睡觉/吐槽(拖动由原生 enableDrag 接管)
/// v0.7.0:气泡完整显示(顶部横条不越界) + 闲置自动贴边缩头 + 透明度实时同步
/// + 交互重定义:单击=摸头 / 双击=戳肚子吐槽 / 长按=呼出喂食+隐藏面板
class SpiritOverlay extends StatefulWidget {
  const SpiritOverlay({super.key});

  @override
  State<SpiritOverlay> createState() => _SpiritOverlayState();
}

class _SpiritOverlayState extends State<SpiritOverlay>
    with SingleTickerProviderStateMixin {
  String? _bubble;
  Timer? _bubbleTimer;
  Timer? _decayTimer;
  Timer? _boredTimer;
  Timer? _autoHideTimer;
  Timer? _panelTimer;
  StreamSubscription<dynamic>? _overlaySub;
  SpiritPhase _phase = SpiritPhase.egg;
  bool _loaded = false;
  bool _evolving = false;
  bool _sleeping = false;
  bool _mini = false;
  bool _panelOpen = false;

  static const double _bigW = 200;
  static const double _bigH = 240;
  static const double _miniW = 76;
  static const double _miniH = 96;

  @override
  void initState() {
    super.initState();
    _overlaySub = FlutterOverlayWindow.overlayListener.listen(_onOverlayEvent);
    _init();
  }

  Future<void> _init() async {
    // 与主 App 共用同一孵化倒计时
    await SpiritStore.ensureHatchTimer();
    final ph = await SpiritStore.load();
    await SpiritState.load();
    await SpiritConfig.load();
    if (!mounted) return;
    setState(() {
      _phase = ph;
      _loaded = true;
    });
    _checkSleep();
    _decayTimer = Timer.periodic(const Duration(seconds: 30), (_) => _onDecay());
    _boredTimer = Timer.periodic(const Duration(seconds: 60), (_) => _onBored());
    _resetAutoHide();
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _decayTimer?.cancel();
    _boredTimer?.cancel();
    _autoHideTimer?.cancel();
    _panelTimer?.cancel();
    _overlaySub?.cancel();
    super.dispose();
  }

  /// 主 App 设置透明化后通过 shareData 实时同步
  void _onOverlayEvent(dynamic event) {
    if (event == null) return;
    double? op;
    try {
      if (event is String) {
        final m = jsonDecode(event);
        if (m is Map) op = (m['opacity'] as num?)?.toDouble();
      } else if (event is Map) {
        op = (event['opacity'] as num?)?.toDouble();
      }
    } catch (_) {}
    if (op != null && mounted) {
      setState(() => SpiritConfig.opacity = (op ?? 1.0).clamp(0.4, 1.0).toDouble());
    }
  }

  /// 互动后重置自动隐藏计时
  void _touchAndReset() {
    SpiritState.touch();
    _resetAutoHide();
  }

  void _resetAutoHide() {
    _autoHideTimer?.cancel();
    if (!SpiritConfig.autoHide || _mini) return;
    _autoHideTimer = Timer(
      Duration(seconds: SpiritConfig.autoHideDelay),
      _goMini,
    );
  }

  Future<void> _goMini() async {
    if (!_loaded || _mini) return;
    _mini = true;
    _panelOpen = false;
    _bubbleTimer?.cancel();
    setState(() {
      _bubble = '🫥 我先缩起来啦~点我出来';
    });
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
    await FlutterOverlayWindow.resizeOverlay(_miniW.toInt(), _miniH.toInt(), true);
    await FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 160));
  }

  Future<void> _restore() async {
    if (!_mini) return;
    _mini = false;
    _panelOpen = false;
    _bubble = null;
    setState(() {});
    await FlutterOverlayWindow.resizeOverlay(_bigW.toInt(), _bigH.toInt(), true);
    await FlutterOverlayWindow.moveOverlay(const OverlayPosition(60, 180));
    _resetAutoHide();
  }

  Future<void> _onTapMini() async {
    _touchAndReset();
    await _restore();
    _pet();
  }

  void _checkSleep() {
    final idle = DateTime.now().difference(SpiritState.lastInteract).inSeconds;
    final shouldSleep = idle > 90;
    if (_sleeping == shouldSleep) return;
    _sleeping = shouldSleep;
    if (!mounted) return;
    setState(() {
      if (_sleeping) {
        _bubble = '💤 Zzz…';
      } else {
        _bubble = null;
      }
    });
  }

  void _onDecay() {
    SpiritState.decay();
    SpiritState.save();
    _checkSleep();
    if (!mounted) return;
    if (SpiritState.satiety < 30) {
      _bubbleTimer?.cancel();
      setState(() => _bubble = '🍽️ 我饿啦!快喂我~');
      _bubbleTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _bubble = null);
      });
    }
    setState(() {});
  }

  /// 长时间不动:小文字弹窗 + 语音吐槽(40 秒起)
  void _onBored() {
    if (!_loaded || _sleeping) return;
    final idle = DateTime.now().difference(SpiritState.lastInteract).inSeconds;
    if (idle < 40) return;
    SpiritState.touch();
    _resetAutoHide();
    final pool = _phase == SpiritPhase.spirit ? kSpiritTaunts : kTaunts;
    final text = pool[_randomInt(pool.length)];
    if (!mounted) return;
    _bubbleTimer?.cancel();
    setState(() => _bubble = text);
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
    SpiritTts.speak(text);
  }

  /// 双击/小窗点击:吐槽文字
  void _onTap() {
    _touchAndReset();
    if (_sleeping) {
      _sleeping = false;
    }
    _bubbleTimer?.cancel();
    final pool = _phase == SpiritPhase.spirit ? kSpiritTaunts : kTaunts;
    final text = pool[_randomInt(pool.length)];
    setState(() => _bubble = text);
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
    SpiritTts.speak(text);
  }

  /// 单击:摸头(第一反应)
  Future<void> _pet() async {
    _touchAndReset();
    SpiritState.mood = math.min(100, SpiritState.mood + 10);
    await SpiritState.save();
    if (!mounted) return;
    _bubbleTimer?.cancel();
    setState(() => _bubble = '💗 摸摸头~心情+10');
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
    SpiritTts.speak('好舒服呀,再摸摸');
  }

  Future<void> _feed(Food food) async {
    _touchAndReset();
    SpiritState.satiety = math.min(100, SpiritState.satiety + food.satiety);
    SpiritState.mood = math.min(100, SpiritState.mood + food.mood);
    SpiritState.feedCount++;
    await SpiritState.save();
    if (!mounted) return;
    _bubbleTimer?.cancel();
    setState(() => _bubble = '${food.emoji} 好好吃~(+${food.satiety})');
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
    SpiritTts.speak('${food.name}好好吃呀,谢谢主人');
    if (!SpiritState.evo && SpiritState.feedCount >= 10) {
      await _evolve();
    }
  }

  Future<void> _evolve() async {
    SpiritState.evo = true;
    await SpiritState.save();
    if (!mounted) return;
    _bubbleTimer?.cancel();
    setState(() {
      _evolving = true;
      _bubble = '✨ 进化啦!完全体 ✨';
    });
    SpiritTts.speak('哇,我进化啦!');
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _evolving = false);
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  void _onHatchComplete() {
    setState(() => _phase = SpiritPhase.spirit);
    SpiritStore.save(SpiritPhase.spirit);
    _bubbleTimer?.cancel();
    setState(() => _bubble = kSpiritTaunts.first);
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
    SpiritTts.speak(kSpiritTaunts.first);
  }

  /// 悬浮窗里点蛋:先过 5 分钟孵化倒计时
  void _onEggTap() {
    if (SpiritStore.remainingSeconds() > 0) {
      _onHatchBlocked();
      return;
    }
    _onHatchComplete();
  }

  /// 孵化未到时间:气泡提示剩余时间
  void _onHatchBlocked() {
    final sec = SpiritStore.remainingSeconds();
    final m = sec ~/ 60;
    final s = sec % 60;
    _bubbleTimer?.cancel();
    setState(() => _bubble = '⏳ 还在孵化… ${m}分${s}秒后可破壳');
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  /// 长按:呼出操作面板(喂食+隐藏),4 秒自动收起
  void _openPanel() {
    if (_phase != SpiritPhase.spirit) return;
    _touchAndReset();
    _panelTimer?.cancel();
    setState(() => _panelOpen = true);
    _panelTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _panelOpen = false);
    });
  }

  void _closePanel() {
    _panelTimer?.cancel();
    if (!mounted) return;
    setState(() => _panelOpen = false);
  }

  int _randomInt(int max) => DateTime.now().millisecondsSinceEpoch % max;

  Widget _roundBtn({
    required VoidCallback onTap,
    required String emoji,
    required double s,
    bool danger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: s,
        height: s,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: danger ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          border: Border.all(color: danger ? Colors.redAccent : Colors.black12),
        ),
        child: Text(emoji, style: TextStyle(fontSize: s * 0.62)),
      ),
    );
  }

  Widget _statBar(String icon, int value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 9)),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (value / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: Colors.white70,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final center = Offset(w / 2, h / 2);
          final size = math.min(w * 0.56, h * 0.52);
          final btnSize = 28.0;
          final foodTop = center.dy + size * 0.72;

          // 缩头贴边态:只显示大头,点击恢复+摸头,双击吐槽
          if (_mini) {
            final miniSize = math.min(w * 0.92, h * 0.86);
            return Opacity(
              opacity: SpiritConfig.opacity,
              child: GestureDetector(
                onTap: _onTapMini,
                onDoubleTap: _onTap,
                child: Center(
                  child: SpiritAvatar(
                    phase: _phase,
                    size: miniSize,
                    evo: SpiritState.evo,
                    sleep: _sleeping,
                  ),
                ),
              ),
            );
          }

          return Opacity(
            opacity: SpiritConfig.opacity,
            child: Stack(
              children: [
                // 进化闪光
                if (_evolving)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.85),
                          boxShadow: const [
                            BoxShadow(color: Colors.amberAccent, blurRadius: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 气泡:顶部横条完整显示,不再越界被切
                if (_bubble != null)
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 6,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 170),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                        child: Text(
                          _bubble!,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                // 灵宠(单击摸头 / 双击吐槽 / 长按面板;蛋形态单击破壳)
                Positioned(
                  left: center.dx - size / 2,
                  top: center.dy - size * 0.62,
                  child: GestureDetector(
                    onTap: _phase == SpiritPhase.egg ? _onEggTap : _pet,
                    onDoubleTap: _phase == SpiritPhase.egg ? null : _onTap,
                    onLongPress: _phase == SpiritPhase.egg ? null : _openPanel,
                    child: SpiritAvatar(
                      phase: _phase,
                      size: size,
                      evo: SpiritState.evo,
                      sleep: _sleeping,
                      onHatchComplete: _onHatchComplete,
                      onHatchBlocked: _onHatchBlocked,
                    ),
                  ),
                ),
                // 饱腹度/心情细条
                Positioned(
                  left: center.dx - 70,
                  top: foodTop - 16,
                  child: SizedBox(
                    width: 140,
                    child: Row(
                      children: [
                        _statBar('🍽️', SpiritState.satiety, const Color(0xFFFF9800)),
                        const SizedBox(width: 6),
                        _statBar('😊', SpiritState.mood, const Color(0xFFE91E63)),
                      ],
                    ),
                  ),
                ),
                // 操作面板(长按呼出):3种食物 + 摸头 + 隐藏;平时隐藏,界面更干净
                if (_panelOpen)
                  Positioned(
                    left: center.dx - 88,
                    top: foodTop,
                    child: Row(
                      children: [
                        for (final f in kFoods) _roundBtn(onTap: () => _feed(f), emoji: f.emoji, s: btnSize),
                        _roundBtn(onTap: _pet, emoji: '💗', s: btnSize),
                        _roundBtn(onTap: _goMini, emoji: '🫥', s: btnSize, danger: true),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
