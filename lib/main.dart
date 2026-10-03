import 'package:flutter/material.dart';

void main() {
  runApp(const DesktopSpiritApp());
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EggWidget(),
            const SizedBox(height: 24),
            Text('桌面灵宠', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('一颗蛋正在孵化中…', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// 会呼吸浮动的蛋(第1步占位动画,后续替换为豆包序列帧)
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
