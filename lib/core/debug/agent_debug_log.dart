import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Debug-mode logger (session 7aed00).
/// Solo `debugPrint` — sin HTTP ni file I/O en el isolate de UI.
/// (HttpClient a 127.0.0.1/LAN sin timeout ralentizaba el launch en device.)
void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const {},
  String runId = 'pre',
}) {
  if (!kDebugMode) return;
  // #region agent log
  final payload = <String, Object?>{
    'sessionId': '7aed00',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  debugPrint('AGENT_DEBUG ${jsonEncode(payload)}');
  // #endregion
}
