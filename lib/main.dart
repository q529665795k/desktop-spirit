// 桌面灵宠 v0.9.0
library main;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/pet_models.dart';
import 'service/pet_state.dart';
import 'service/storage_service.dart';
import 'service/tts_service.dart';
import 'service/accessibility_service.dart';
import 'service/asset_manager.dart';
import 'service/llm_service.dart';
import 'service/voice_wake_service.dart';
import 'widget/avatar_widget.dart';
import 'widget/panel_widget.dart';
import 'widget/egg_widget.dart';
import 'widget/overlay_bubble.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: PetState.I,
      child: MaterialApp(
        title: '桌面灵宠',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final PetState _state = PetState.I;
  final StorageService _storage = StorageService.I;
  final AccessibilityService _a11y = AccessibilityService.I;
  final TTSService _tts = TTSService.I;
  final AssetManager _assets = AssetManager.I;
  final LLMService _llm = LLMService.I;
  final VoiceWakeService _voiceWake = VoiceWakeService.I;

  OverlayPosition _pos = const OverlayPosition(100, 100);
  bool _panelOpen = false;
  bool _loaded = false;
  bool _mini = false;
  String _status = '初始化中...';
  bool _hatchDone = false;
  final GlobalKey _bubbleKey = GlobalKey();

  static const double _miniW = 76;
  static const double _miniH = 96;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _a11y.refreshIcons();
      if (_hatchDone) _state.showBubble('欢迎回来！', _pos.dx, _pos.dy);
    }
  }

  Future<void> _initAll() async {
    await Future.wait([
      _storage.init(),
      _tts.init(),
      _a11y.init(),
      _assets.init(),
      _voiceWake.init(),
    ]);
    await _state.init(_storage, _tts, _a11y, _assets, _llm, _voiceWake);
    await _llm.init();
    _voiceWake.onWake = _onVoiceWake;

    _a11y.windowChangeStream.listen((pkg) {
      if (_state.phase != 'sleep') _state.setAction('idle');
    });

    _a11y.iconsStream.listen((icons) {
      // 漫游吃图标已移除
    });

    setState(() {
      _loaded = true;
      _status = _hatchDone ? '就绪' : '孵化中...';
    });
  }

  void _onVoiceWake() {
    if (!_hatchDone) return;
    _state.setAction('happy');
    _state.showBubble('我在呢！', _pos.dx, _pos.dy);
  }

  void _onHatched() {
    setState(() {
      _hatchDone = true;
      _status = '欢迎新精灵！';
    });
    _tts.speak('欢迎来到桌面灵宠！');
    Future.delayed(const Duration(seconds: 2), _state.startMainLoop);
  }

  void _showBubble(String text) {
    final RenderBox? box = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      _state.showBubble(text, pos.dx, pos.dy);
    }
  }

  void _openPanel() {
    setState(() => _panelOpen = true);
    _state.setAction('happy');
  }

  void _toggleMini() {
    setState(() => _mini = !_mini);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (!_hatchDone)
            EggWidget(onHatched: _onHatched)
          else ...[
            Positioned(
              left: _pos.dx,
              top: _pos.dy,
              child: GestureDetector(
                onTap: _openPanel,
                onDoubleTap: _toggleMini,
                onPanUpdate: _loaded && !_mini ? (details) {
                  setState(() {
                    _pos = OverlayPosition(
                      (_pos.dx + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - (_mini ? _miniW : 200)),
                      (_pos.dy + details.delta.dy).clamp(0.0, MediaQuery.of(context).size.height - (_mini ? _miniH : 200)),
                    );
                  });
                  _state.updatePosition(_pos);
                } : null,
                child: _mini
                    ? SizedBox(
                        width: _miniW,
                        height: _miniH,
                        child: AvatarWidget(
                          phase: _state.phase,
                          action: _state.currentAction,
                          sleeping: _state.isSleeping,
                          assets: _assets,
                        ),
                      )
                    : SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          children: [
                            AvatarWidget(
                              phase: _state.phase,
                              action: _state.currentAction,
                              sleeping: _state.isSleeping,
                              assets: _assets,
                            ),
                            if (_state.showBubbleText != null)
                              Positioned(
                                top: -40,
                                left: 100,
                                child: OverlayBubble(
                                  text: _state.showBubbleText!,
                                  x: 100,
                                  y: -40,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
            if (_panelOpen)
              PanelWidget(
                onClose: () => setState(() => _panelOpen = false),
              ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }
}


