// 多屏适配 / 尺度换算
library service.screen;

import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class ScreenMetrics {
  static double _dpRatio = 1.0;
  static double _screenW = 0;
  static double _screenH = 0;
  static bool _initialized = false;

  // 从原生获取真实屏幕尺寸（dp）
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // 优先用平台视图获取
      final size = await _getNativeScreenSize();
      _screenW = size['width']!.toDouble();
      _screenH = size['height']!.toDouble();
    } catch (_) {
      // 回退：Flutter window
      final view = ui.PlatformDispatcher.instance.implicitView;
      if (view != null) {
        _screenW = view.physicalSize.width / view.devicePixelRatio;
        _screenH = view.physicalSize.height / view.devicePixelRatio;
      }
    }

    // Android dp ratio（大多数设备 1dp = 1px @160dpi）
    // 这里简化处理，实际可通过方法通道获取 density
    _dpRatio = 1.0;
    _initialized = true;
  }

  static Future<Map<String, num>> _getNativeScreenSize() async {
    const channel = MethodChannel('desktop_spirit/screen');
    return Map<String, num>.from(await channel.invokeMethod('getScreenSize'));
  }

  // dp -> px
  static double dp(double dp) => dp * _dpRatio;

  // px -> dp
  static double px(double px) => px / _dpRatio;

  static double get screenWdp => _screenW;
  static double get screenHdp => _screenH;
  static double get screenWpx => _screenW * _dpRatio;
  static double get screenHpx => _screenH * _dpRatio;

  static bool get initialized => _initialized;

  // 安全区域（刘海/水滴屏/手势栏）
  static ui.WindowPadding get padding => ui.PlatformDispatcher.instance.implicitView?.padding ?? ui.WindowPadding.zero;

  static double get topSafe => padding.top / _dpRatio;
  static double get bottomSafe => padding.bottom / _dpRatio;
  static double get leftSafe => padding.left / _dpRatio;
  static double get rightSafe => padding.right / _dpRatio;
}