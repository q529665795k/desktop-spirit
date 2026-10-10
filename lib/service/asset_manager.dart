// 资产管理器（动态加载、缓存、自定义形象支持）
library service.asset_manager;

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class AssetManager {
  AssetManager._();
  static final AssetManager _instance = AssetManager._();
  static AssetManager get I => _instance;

  final Map<String, List<String>> _assetCache = {};
  final StreamController<String> _reloadController = StreamController.broadcast();
  bool _initialized = false;

  Stream<String> get reloadStream => _reloadController.stream;

  Future<void> init() async {
    if (_initialized) return;
    await _scanAssets();
    _initialized = true;
  }

  Future<void> _scanAssets() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final lines = manifest.split('\n');
    for (final line in lines) {
      final path = line.trim();
      if (path.isEmpty) continue;
      if (path.endsWith('.png') && path.startsWith('assets/')) {
        final dir = path.split('/')[1]; // assets/xxx/yyy.png -> xxx
        _assetCache.putIfAbsent(dir, () => []).add(path);
      }
    }
    // 排序确保帧序正确
    _assetCache.forEach((_, list) => list.sort());
  }

  /// 获取某动画目录下的所有帧
  List<String> getFrames(String dir) => List.unmodifiable(_assetCache[dir] ?? []);

  /// 获取帧数
  int getFrameCount(String dir) => _assetCache[dir]?.length ?? 1;

  /// 检查目录是否存在
  bool hasDir(String dir) => _assetCache.containsKey(dir);

  /// 自定义形象路径
  String? getCustomAvatarPath() => StorageService.I.getCustomAvatar();

  /// 设置自定义形象（从文件选择器返回的路径）
  Future<void> setCustomAvatar(String path) async {
    await StorageService.I.setCustomAvatar(path);
    _reloadController.add('customAvatar');
  }

  /// 清除自定义形象
  Future<void> clearCustomAvatar() async {
    await StorageService.I.setCustomAvatar('');
    _reloadController.add('customAvatar');
  }

  /// 获取形象偏移/缩放
  Map<String, double> getAvatarTransform() {
    final offset = StorageService.I.getAvatarOffset();
    return {'x': offset.dx, 'y': offset.dy, 'scale': 1.0};
  }
  /// 获取自定义形象某方向的帧路径（若有）
  String? getCustomPath(String phase, String dir) {
    final customPath = getCustomAvatarPath();
    if (customPath.isEmpty) return null;
    // 自定义形象目录结构: assets/custom/{setName}/{dir}/frame_01.png
    final customDir = 'assets/custom/$customPath/$dir';
    if (hasDir(customDir)) {
      final frames = getFrames(customDir);
      if (frames.isNotEmpty) return frames.first; // 返回第一帧作为示例
    }
    return null;
  }

  /// 设置形象偏移/缩放
  Future<void> setAvatarTransform(double x, double y, double scale) async {
    await StorageService.I.setAvatarOffset(Offset(x, y));
    _reloadController.add('avatarTransform');
  }

  /// 重新扫描（热更后调用）
  Future<void> rescan() async {
    _assetCache.clear();
    await _scanAssets();
    _reloadController.add('rescan');
  }

  /// 所有可用动画目录
  List<String> get availableDirs => _assetCache.keys.toList()..sort();

  void dispose() {
    _reloadController.close();
  }
}