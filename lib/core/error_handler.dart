// 统一错误处理与上报
library error_handler;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'events.dart';

class SpiritError implements Exception {
  final String code;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  SpiritError({
    required this.code,
    required this.message,
    this.originalError,
    this.stackTrace,
    Map<String, dynamic>? context,
  })  : timestamp = DateTime.now(),
        context = context ?? {};

  @override
  String toString() =>
      '[SpiritError:$code] $message\n${stackTrace ?? originalError}';
}

class ErrorHandler {
  ErrorHandler._();
  static final ErrorHandler instance = ErrorHandler._();

  static const _maxStoredErrors = 100;
  static const _prefsKey = 'error_log';

  bool _initialized = false;
  SharedPreferences? _prefs;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  void handleError(
    dynamic error, [
    StackTrace? stack,
    String? code,
    Map<String, dynamic>? context,
  ]) {
    final spiritError = error is SpiritError
        ? error
        : SpiritError(
            code: code ?? 'UNKNOWN',
            message: error.toString(),
            originalError: error,
            stackTrace: stack,
            context: context,
          );

    // 本地记录
    _storeError(spiritError);

    // 发送事件供 UI/统计使用
    EventBus.instance.emit(ErrorOccurredEvent(spiritError.message, spiritError.stackTrace));

    // Debug 模式下打印
    if (kDebugMode) {
      debugPrint('❌ $spiritError');
    }
  }

  void handleErrorAsync(Future<void> Function() fn, {String? code, Map<String, dynamic>? context}) {
    fn().catchError((e, s) => handleError(e, s, code: code, context: context));
  }

  Future<void> _storeError(SpiritError error) async {
    if (!_initialized) await init();
    final list = _prefs?.getStringList(_prefsKey) ?? [];
    list.insert(0, error.toString());
    if (list.length > _maxStoredErrors) list.removeRange(_maxStoredErrors, list.length);
    await _prefs?.setStringList(_prefsKey, list);
  }

  List<String> getStoredErrors() {
    return _prefs?.getStringList(_prefsKey) ?? [];
  }

  Future<void> clearErrors() async {
    await _prefs?.remove(_prefsKey);
  }
}

/// 便捷扩展
extension ErrorHandling on Future<void> {
  Future<void> safe({String? code, Map<String, dynamic>? context}) {
    return catchError((e, s) =>
        ErrorHandler.instance.handleError(e, s, code: code, context: context));
  }
}