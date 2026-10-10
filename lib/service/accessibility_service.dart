// 无障碍服务桥接（窗口切换、应用列表、图标检测预留）
library accessibility_service;

import 'dart:async';
import 'package:flutter/services.dart';
import '../model/pet_models.dart';

class AccessibilityService {
  AccessibilityService._();
  static final AccessibilityService _instance = AccessibilityService._();
  static AccessibilityService get I => _instance;

  static const _channel = MethodChannel('com.desktop_spirit/accessibility');

  final _iconsController = StreamController<List<DetectedIcon>>.broadcast();
  final _windowChangeController = StreamController<String>.broadcast();
  final _permissionController = StreamController<bool>.broadcast();

  Stream<List<DetectedIcon>> get iconsStream => _iconsController.stream;
  Stream<String> get windowChangeStream => _windowChangeController.stream;
  Stream<bool> get permissionStream => _permissionController.stream;

  bool _initialized = false;
  bool _permissionGranted = false;
  Timer? _refreshTimer;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _permissionGranted = await _channel.invokeMethod('checkPermission') ?? false;
      _permissionController.add(_permissionGranted);
      _initialized = true;
    } catch (_) {
      // 原生未实现
    }
  }

  Future<bool> requestPermission() async {
    try {
      _permissionGranted = await _channel.invokeMethod('requestPermission') ?? false;
      _permissionController.add(_permissionGranted);
      return _permissionGranted;
    } catch (_) {
      return false;
    }
  }

  /// 获取当前屏幕上的应用图标列表
  Future<List<DetectedIcon>> getIcons() async {
    try {
      final result = await _channel.invokeMethod('getIcons');
      if (result is List) {
        return result.map((e) => DetectedIcon.fromMap(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// 刷新图标（触发原生扫描并推流）
  Future<void> refreshIcons() async {
    try {
      await _channel.invokeMethod('refreshIcons');
    } catch (_) {}
  }

  /// 启动定期刷新
  void startPeriodicRefresh({Duration interval = const Duration(seconds: 10)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => refreshIcons());
  }

  /// 停止定期刷新
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 获取最近的图标（用于交互判断，预留接口）
  DetectedIcon? getNearestIcon(double cx, double cy, {double radius = 80}) {
    // 实现需要原生端配合，暂返回 null
    return null;
  }

  /// 获取已安装应用列表（用于设置面板）
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      if (result is List) {
        return result.map((e) => AppInfo.fromMap(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  void dispose() {
    _refreshTimer?.cancel();
    _iconsController.close();
    _windowChangeController.close();
    _permissionController.close();
    _initialized = false;
  }
}

/// 检测到的桌面图标
class DetectedIcon {
  final String packageName;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;

  DetectedIcon({
    required this.packageName,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory DetectedIcon.fromMap(Map map) {
    return DetectedIcon(
      packageName: map['packageName'] as String,
      label: map['label'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
    );
  }
}

/// 应用信息
class AppInfo {
  final String packageName;
  final String label;
  final String iconPath;

  AppInfo({
    required this.packageName,
    required this.label,
    required this.iconPath,
  });

  factory AppInfo.fromMap(Map map) {
    return AppInfo(
      packageName: map['packageName'] as String,
      label: map['label'] as String,
      iconPath: map['iconPath'] as String? ?? '',
    );
  }
}