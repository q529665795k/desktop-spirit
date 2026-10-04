import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

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

class DesktopSpiritApp extends StatelessWidget {
  const DesktopSpiritApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '桌面灵宠',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8E7CC3),
      ),
      home: const HomePage(),
    );
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

  @override
  void initState() {
    super.initState();
    _checkPermission();
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
    if (!_permission) {
      final ok = await FlutterOverlayWindow.requestPermission();
      if (!mounted) return;
      if (ok != true) {
        setState(() {
          _permission = false;
          _status = '权限被拒绝,请在系统设置里手动打开"显示在其他应用上层"';
        });
        return;
      }
      setState(() {
        _permission = true;
        _status = '悬浮窗权限:已授权';
      });
    }
    await FlutterOverlayWindow.showOverlay(
      height: 220,
      width: 180,
      overlayTitle: '桌面灵宠',
      overlayContent: '灵宠悬浮窗',
      flag: OverlayFlag.defaultFlag,
      enableDrag: true,
    );
    if (!mounted) return;
    setState(() => _overlayVisible = true);
  }

  Future<void> _stop() async {
    await FlutterOverlayWindow.closeOverlay();
    if (!mounted) return;
    setState(() => _overlayVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EggWidget(),
            const SizedBox(height: 24),
            Text('桌面灵宠', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('一颗蛋正在孵化中…', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            Text(_status, style: theme.textTheme.bodySmall),
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
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '小提示:悬浮窗开启后回桌面就能看到蛋,可以拖动,点它会吐槽',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 会呼吸浮动的蛋(占位动画,后续替换为豆包序列帧)
class EggWidget extends StatefulWidget {
  const EggWidget({super.key});

  @override
  State<EggWidget> createState() => _EggWidgetState();
}

class _EggWidgetState extends State<EggWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Transform.translate(
          offset: Offset(0, -t * 10),
          child: Transform.scale(scale: 1 + t * 0.04, child: child),
        );
      },
      child: Container(
        width: 130,
        height: 160,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFFDF6FF), Color(0xFFC9B8F5), Color(0xFF9C8ADF)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x668E7CC3),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.egg, size: 96, color: Color(0xFFFFF8F0)),
      ),
    );
  }
}

/// 悬浮窗:一颗会呼吸、点击冒泡的蛋(拖动由原生 enableDrag 接管)
class SpiritOverlay extends StatefulWidget {
  const SpiritOverlay({super.key});

  @override
  State<SpiritOverlay> createState() => _SpiritOverlayState();
}

class _SpiritOverlayState extends State<SpiritOverlay>
    with SingleTickerProviderStateMixin {
  String? _bubble;
  Timer? _bubbleTimer;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    _bubbleTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    _bubbleTimer?.cancel();
    setState(() {
      _bubble = kTaunts[_randomInt(kTaunts.length)];
    });
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  int _randomInt(int max) => DateTime.now().millisecondsSinceEpoch % max;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          return Stack(
            children: [
              // 气泡(显示在蛋上方)
              if (_bubble != null)
                Positioned(
                  left: center.dx - 70,
                  top: center.dy - 170,
                  child: Container(
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              // 蛋(点击冒泡;整个悬浮窗拖动由原生 enableDrag 处理)
              Positioned(
                left: center.dx - 65,
                top: center.dy - 80,
                child: GestureDetector(
                  onTap: _onTap,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) {
                      final t = _anim.value;
                      return Transform.translate(
                        offset: Offset(0, -t * 8),
                        child: Transform.scale(
                          scale: 1 + t * 0.04,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 130,
                      height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFFDF6FF),
                            Color(0xFFC9B8F5),
                            Color(0xFF9C8ADF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x668E7CC3),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.egg,
                        size: 96,
                        color: Color(0xFFFFF8F0),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
