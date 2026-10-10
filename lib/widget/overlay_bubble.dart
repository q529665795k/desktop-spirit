// 气泡组件
library widget.overlay_bubble;

import 'package:flutter/material.dart';

class OverlayBubble extends StatelessWidget {
  final String text;
  final double x;
  final double y;

  const OverlayBubble({
    super.key,
    required this.text,
    required this.x,
    required this.y,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - 80,
      top: y,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}