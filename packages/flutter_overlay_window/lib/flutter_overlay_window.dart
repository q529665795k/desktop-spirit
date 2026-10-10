// flutter_overlay_window plugin
library flutter_overlay_window;

import 'dart:async';
import 'package:flutter/services.dart';

/// Overlay window status
enum OverlayStatus {
  unknown,
  running,
  stopped,
  error,
}

/// Window position
class WindowPosition {
  final double x;
  final double y;
  const WindowPosition(this.x, this.y);
}

/// Window size
class WindowSize {
  final double width;
  final double height;
  const WindowSize(this.width, this.height);
}

/// Main plugin class
class FlutterOverlayWindow {
  static const MethodChannel _channel = MethodChannel('flutter_overlay_window');

  /// Check if overlay is supported on current platform
  static Future<bool> isOverlaySupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isOverlaySupported');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Request overlay permission
  static Future<bool> requestOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Check if overlay permission is granted
  static Future<bool> isOverlayPermissionGranted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isOverlayPermissionGranted');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Start overlay with given configuration
  static Future<bool> startOverlay({
    required String title,
    required String content,
    int flags = 0,
    int width = 400,
    int height = 600,
    int x = 100,
    int y = 100,
    bool focusable = true,
    bool enableDrag = true,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('startOverlay', {
        'title': title,
        'content': content,
        'flags': flags,
        'width': width,
        'height': height,
        'x': x,
        'y': y,
        'focusable': focusable,
        'enableDrag': enableDrag,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Stop overlay
  static Future<bool> stopOverlay() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopOverlay');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Update overlay position
  static Future<bool> updatePosition(double x, double y) async {
    try {
      final result = await _channel.invokeMethod<bool>('updatePosition', {
        'x': x,
        'y': y,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Update overlay size
  static Future<bool> updateSize(double width, double height) async {
    try {
      final result = await _channel.invokeMethod<bool>('updateSize', {
        'width': width,
        'height': height,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Get overlay status
  static Future<OverlayStatus> getOverlayStatus() async {
    try {
      final result = await _channel.invokeMethod<String>('getOverlayStatus');
      return OverlayStatus.values.byName(result ?? 'unknown');
    } on PlatformException {
      return OverlayStatus.error;
    }
  }

  /// Set overlay click-through mode
  static Future<bool> setClickThrough(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>('setClickThrough', {
        'enabled': enabled,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Bring overlay to front
  static Future<bool> bringToFront() async {
    try {
      final result = await _channel.invokeMethod<bool>('bringToFront');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Set overlay visibility
  static Future<bool> setVisibility(bool visible) async {
    try {
      final result = await _channel.invokeMethod<bool>('setVisibility', {
        'visible': visible,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Get overlay position
  static Future<WindowPosition?> getPosition() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getPosition');
      if (result != null) {
        return WindowPosition(
          (result['x'] as num).toDouble(),
          (result['y'] as num).toDouble(),
        );
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Get overlay size
  static Future<WindowSize?> getSize() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSize');
      if (result != null) {
        return WindowSize(
          (result['width'] as num).toDouble(),
          (result['height'] as num).toDouble(),
        );
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Add listener for overlay events
  static void addListener(Function(OverlayStatus) listener) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOverlayStatusChanged') {
        final status = OverlayStatus.values.byName(call.arguments as String);
        listener(status);
      }
    });
  }

  /// Remove listener
  static void removeListener() {
    _channel.setMethodCallHandler(null);
  }
}