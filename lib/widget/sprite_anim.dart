// 精灵动画组件
library widget.sprite_anim;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpriteAnim extends StatefulWidget {
  final String dir;
  final int fps;
  final int? frameCount;
  final bool loop;
  final VoidCallback? onComplete;

  const SpriteAnim({
    super.key,
    required this.dir,
    this.fps = 8,
    this.frameCount,
    this.loop = true,
    this.onComplete,
  });

  @override
  State<SpriteAnim> createState() => _SpriteAnimState();
}

class _SpriteAnimState extends State<SpriteAnim> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _frame = 0;
  int _frames = 1;
  static const _counts = {
    'idle': 5, 'angry': 3, 'dance': 5, 'eat': 5,
    'happy': 3, 'hungry': 3, 'roll': 5, 'sleep': 4,
    'talk': 3, 'walk': 5, 'final': 5,
  };

  @override
  void initState() {
    super.initState();
    _frames = widget.frameCount ?? _counts[widget.dir] ?? 1;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000 / widget.fps).round() * _frames),
    )..repeat();
    _controller.addListener(_tick);
  }

  void _tick() {
    final f = (_controller.value * _frames).floor().clamp(0, _frames - 1);
    if (f != _frame && mounted) setState(() => _frame = f);
  }

  @override
  void didUpdateWidget(covariant SpriteAnim oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dir != widget.dir || oldWidget.fps != widget.fps) {
      _frames = widget.frameCount ?? _counts[widget.dir] ?? 1;
      _controller.duration = Duration(milliseconds: (1000 / widget.fps).round() * _frames);
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = 'assets/$dir/${widget.dir}_${_frame + 1}.png';
    return Image.asset(
      asset,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}