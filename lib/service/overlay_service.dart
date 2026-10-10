// 覆盖窗口服务（FlutterOverlayWindow 封装、位置/大小/点击穿透）
library service.overlay_service;

import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/services.dart';

class OverlayService {
  OverlayService._();
  static final OverlayService _instance = OverlayService._();
  static OverlayService get I => _instance;

  bool _isOverlayActive = false;
  double _lastX = 0, _lastY = 0;
  double _lastW = 200, _lastH = 200;

  Future<void> init() async {
    await FlutterOverlayWindow.initialize();
    _isOverlayActive = await FlutterOverlayWindow.isOverlayWindowVisible() ?? false;
  }

  Future<void> showOverlay({double? x, double? y, double? w, double? h}) async {
    if (_isOverlayActive) {
      await resizeOverlay(w?.toInt() ?? _lastW.toInt(), h?.toInt() ?? _lastH.toInt());
      if (x != null && y != null) {
        await moveOverlay(x, y);
      }
      return;
    }

    _lastX = x ?? 100;
    _lastY = y ?? 100;
    _lastW = w ?? 200;
    _lastH = h ?? 200;

    await FlutterOverlayWindow.showOverlay(
      flag: OverlayFlag.defaultFlag,
      width: _lastW.toInt(),
      height: _lastH.toInt(),
      alignment: OverlayAlignment.topLeft,
      startPosition: OverlayPosition(_lastX.toInt(), _lastY.toInt()),
    );
    _isOverlayActive = true;
  }

  Future<void> hideOverlay() async {
    if (!_isOverlayActive) return;
    await FlutterOverlayWindow.closeOverlay();
    _isOverlayActive = false;
  }

  Future<void> moveOverlay(double x, double y) async {
    if (!_isOverlayActive) return;
    _lastX = x;
    _lastY = y;
    await FlutterOverlayWindow.moveOverlay(OverlayPosition(x.toInt(), y.toInt()));
  }

  Future<void> resizeOverlay(int w, int h) async {
    if (!_isOverlayActive) return;
    _lastW = w.toDouble();
    _lastH = h.toDouble();
    await FlutterOverlayWindow.resizeOverlay(w, h, true);
  }

  Future<void> setClickThrough(bool enabled) async {
    if (!_isOverlayActive) return;
    await FlutterOverlayWindow.setOverlayClickThrough(enabled);
  }

  Future<void> updatePosition(double x, double y) async {
    if (!_isOverlayActive) return;
    _lastX = x;
    _lastY = y;
    await FlutterOverlayWindow.moveOverlay(OverlayPosition(x.toInt(), y.toInt()));
  }

  Future<double> getScreenWidth() async {
    try {
      final result = await const MethodChannel('com.marvis.desktop_spirit/overlay')
          .invokeMethod<double>('getScreenWidth');
      return result ?? 1080.0;
    } catch (_) {
      return 1080.0;
    }
  }

  Future<double> getScreenHeight() async {
    try {
      final result = await const MethodChannel('com.marvis.desktop_spirit/overlay')
          .invokeMethod<double>('getScreenHeight');
      return result ?? 1920.0;
    } catch (_) {
      return 1920.0;
    }
  }

  bool get isActive => _isOverlayActive;
  double get lastX => _lastX;
  double get lastY => _lastY;
  double get lastW => _lastW;
  double get lastH => _lastH;
}