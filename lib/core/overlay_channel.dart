// Android 悬浮窗 / 无障碍 通信通道
library overlay_channel;

import 'dart:async';
import 'package:flutter/services.dart';
import '../core/config.dart';

class OverlayChannel {
  OverlayChannel._();
  static final OverlayChannel _instance = OverlayChannel._();
  static OverlayChannel get I => _instance;

  static const MethodChannel _channel = MethodChannel('desktop_spirit/overlay');
  static const EventChannel _iconEventChannel = EventChannel('desktop_spirit/icon_events');

  StreamSubscription? _iconSub;
  Function(Map<String, dynamic>)? _onIconData;
  Function(bool)? _onA11yStatus;

  Future<void> init() async {
    _channel.setMethodCallHandler(_handleMethodCall);
    _iconSub = _iconEventChannel.receiveBroadcastStream().listen(
      (event) => _onIconData?.call(Map<String, dynamic>.from(event)),
      onError: (err) => print('Icon event error: $err'),
    );
    await _checkA11yStatus();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'a11yStatusChanged':
        final enabled = call.arguments?['enabled'] as bool? ?? false;
        _onA11yStatus?.call(enabled);
        break;
      case 'windowTapped':
        // 点击悬浮窗外部
        break;
    }
    return null;
  }

  void setIconCallback(Function(Map<String, dynamic>) cb) => _onIconData = cb;
  void setA11yCallback(Function(bool) cb) => _onA11yStatus = cb;

  // === 悬浮窗控制 ===
  Future<bool> requestPermission() async {
    final result = await _channel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  Future<void> showOverlay({double? x, double? y, int? w, int? h}) async {
    await _channel.invokeMethod('showOverlay', {
      'x': x?.toInt() ?? 100,
      'y': y?.toInt() ?? 200,
      'w': w?.toInt() ?? PetConfig.defaultWinW.toInt(),
      'h': h?.toInt() ?? PetConfig.defaultWinH.toInt(),
    });
  }

  Future<void> hideOverlay() async {
    await _channel.invokeMethod('hideOverlay');
  }

  Future<void> moveOverlay(double x, double y) async {
    await _channel.invokeMethod('moveOverlay', {'x': x.toInt(), 'y': y.toInt()});
  }

  Future<void> resizeOverlay(int w, int h, {bool force = false}) async {
    await _channel.invokeMethod('resizeOverlay', {'w': w, 'h': h, 'force': force});
  }

  Future<void> setOverlayOpacity(double opacity) async {
    await _channel.invokeMethod('setOpacity', {'opacity': opacity.clamp(0.0, 1.0)});
  }

  // === 无障碍服务 ===
  Future<bool> checkA11yEnabled() async {
    final result = await _channel.invokeMethod<bool>('checkA11yEnabled');
    return result ?? false;
  }

  Future<void> _checkA11yStatus() async {
    final enabled = await checkA11yEnabled();
    _onA11yStatus?.call(enabled);
  }

  Future<void> openA11ySettings() async {
    await _channel.invokeMethod('openA11ySettings');
  }

  // === 图标点击 / 吃图标 ===
  Future<void> triggerEatIcon(double iconX, double iconY, String pkgName) async {
    await _channel.invokeMethod('triggerEatIcon', {
      'iconX': iconX.toInt(),
      'iconY': iconY.toInt(),
      'pkg': pkgName,
    });
  }

  Future<List<Map<String, dynamic>>> getDesktopIcons() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getDesktopIcons');
    if (result == null) return [];
    return result.cast<Map<String, dynamic>>();
  }

  // === 屏幕信息 ===
  Future<Map<String, double>> getScreenSize() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getScreenSize');
    if (result == null) return {'width': 1080.0, 'height': 1920.0};
    return {
      'width': (result['width'] as num).toDouble(),
      'height': (result['height'] as num).toDouble(),
    };
  }

  // === 截图（用于 LLM 视觉）===
  Future<Uint8List?> takeScreenshot() async {
    final result = await _channel.invokeMethod<Uint8List>('takeScreenshot');
    return result;
  }

  void dispose() {
    _iconSub?.cancel();
    _iconSub = null;
    _onIconData = null;
    _onA11yStatus = null;
  }
}