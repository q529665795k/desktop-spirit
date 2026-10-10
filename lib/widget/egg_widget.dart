// 破壳孵化动画
library widget.egg_widget;

import 'package:flutter/material.dart';
import 'sprite_anim.dart';

class EggWidget extends StatefulWidget {
  final VoidCallback onHatched;
  const EggWidget({super.key, required this.onHatched});

  @override
  State<EggWidget> createState() => _EggWidgetState();
}

class _EggWidgetState extends State<EggWidget> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  int _phase = 1;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      })
      ..forward();
  }

  void _next() {
    if (_phase < 3) {
      setState(() => _phase++);
      _c.forward(from: 0);
    } else {
      widget.onHatched();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Image.asset(
          'assets/egg/egg_0$_phase.png',
          key: ValueKey(_phase),
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}