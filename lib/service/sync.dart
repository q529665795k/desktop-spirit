// 云同步服务（预留接口，WebDAV/S3等）
library service.sync;

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

abstract class SyncProvider {
  Future<bool> upload(File file, String remotePath);
  Future<bool> download(String remotePath, File localFile);
  Future<List<String>> list(String prefix);
  Future<void> delete(String remotePath);
}

class SyncService {
  static SyncProvider? _provider;
  static bool _syncing = false;

  static void setProvider(SyncProvider provider) {
    _provider = provider;
  }

  // 手动推送备份
  static Future<bool> pushBackup() async {
    if (_provider == null || _syncing) return false;
    _syncing = true;

    try {
      final file = await StorageService.I.exportAll();
      final remotePath = 'spirit/backups/${file.uri.pathSegments.last}';
      final ok = await _provider!.upload(file, remotePath);
      return ok;
    } catch (e) {
      return false;
    } finally {
      _syncing = false;
    }
  }

  // 手动拉取最新备份
  static Future<bool> pullLatest() async {
    if (_provider == null || _syncing) return false;
    _syncing = true;

    try {
      final files = await _provider!.list('spirit/backups/');
      if (files.isEmpty) return false;
      files.sort((a, b) => b.compareTo(a));
      final latest = files.first;
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/${latest.split('/').last}');
      final ok = await _provider!.download(latest, localFile);
      if (ok) {
        await StorageService.I.importAll(localFile);
      }
      return ok;
    } catch (e) {
      return false;
    } finally {
      _syncing = false;
    }
  }

  static bool get isSyncing => _syncing;
}
