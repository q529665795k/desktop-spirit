// 灵宠主体组件
library widget.avatar_widget;

import 'package:flutter/material.dart';
import 'sprite_anim.dart';
import '../service/asset_manager.dart';

class AvatarWidget extends StatelessWidget {
  final String phase;
  final String? action;
  final bool sleeping;
  final AssetManager? assets;

  const AvatarWidget({
    super.key,
    required this.phase,
    this.action,
    required this.sleeping,
    this.assets,
  });

  String get _dir {
    if (sleeping) return 'sleep';
    if (action != null) return action!;
    return 'idle';
  }

  int get _fps {
    switch (_dir) {
      case 'angry': return 6;
      case 'dance': return 10;
      case 'eat': return 5;
      case 'sleep': return 2;
      case 'talk': return 4;
      default: return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customPath = assets?.getCustomPath(phase, _dir);
    if (customPath != null) {
      return Image.asset(customPath, width: 200, height: 200, gaplessPlayback: true);
    }
    return SpriteAnim(dir: _dir, fps: _fps);
  }
}
