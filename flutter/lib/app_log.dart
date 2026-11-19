import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

abstract final class AppLogTag {
  static const workspace = 'Workspace';
  static const profileStore = 'ProfileStore';
  static const terminal = 'Terminal';
  static const dock = 'Dock';
  static const error = 'Error';
}

/// Emits structured diagnostic events in debug builds without exposing
/// terminal input, output, or startup-command contents.
void appLog(
  String tag,
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  if (!kDebugMode) return;
  developer.log(message, name: tag, error: error, stackTrace: stackTrace);
}
