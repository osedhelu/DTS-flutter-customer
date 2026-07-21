import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Debug-mode NDJSON logger (session 7aed00).
/// Solo debugPrint + HTTP async — NUNCA I/O sync en el isolate de UI
/// (writeAsStringSync a /Volumes/Datos bloqueaba el build del Navigator).
void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const {},
  String runId = 'pre',
}) {
  final payload = <String, Object?>{
    'sessionId': '7aed00',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final line = jsonEncode(payload);
  // #region agent log
  debugPrint('AGENT_DEBUG $line');
  try {
    for (final host in ['127.0.0.1', '192.168.0.193']) {
      final uri = Uri.parse(
        'http://$host:7874/ingest/c01cbf28-0f95-4153-b1b8-f0bd60922f91',
      );
      HttpClient()
          .postUrl(uri)
          .then((req) {
            req.headers.set('Content-Type', 'application/json');
            req.headers.set('X-Debug-Session-Id', '7aed00');
            req.write(line);
            return req.close();
          })
          .then((resp) => resp.drain<void>())
          .catchError((_) {});
    }
  } catch (_) {}
  // #endregion
}
