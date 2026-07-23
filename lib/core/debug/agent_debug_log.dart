import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _inFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

/// Debug-session logger (session c4eafd). Do not log secrets/PII.
/// No sync filesystem I/O (blocks isolate during Navigator updates).
void agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, Object?> data = const {},
  String runId = 'pre-fix',
}) {
  final payload = <String, Object?>{
    'sessionId': 'c4eafd',
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
  if (_inFlutterTest) return;
  // Fire-and-forget; never await inside build/Navigator callbacks.
  for (final host in const ['127.0.0.1', '192.168.0.193']) {
    () async {
      HttpClient? client;
      try {
        client = HttpClient()
          ..connectionTimeout = const Duration(milliseconds: 300)
          ..idleTimeout = const Duration(milliseconds: 300);
        final req = await client.postUrl(
          Uri.parse(
            'http://$host:7874/ingest/c01cbf28-0f95-4153-b1b8-f0bd60922f91',
          ),
        );
        req.headers.set('Content-Type', 'application/json');
        req.headers.set('X-Debug-Session-Id', 'c4eafd');
        req.write(line);
        await req.close().timeout(const Duration(milliseconds: 300));
      } catch (_) {
      } finally {
        client?.close(force: true);
      }
    }();
  }
  // #endregion
}

/// Observes Navigator pops/pushes to correlate with go_router crashes.
class AgentNavObserver extends NavigatorObserver {
  AgentNavObserver({this.tag = 'root'});

  final String tag;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // #region agent log
    agentDebugLog(
      location: 'agent_debug_log.dart:didPush',
      message: 'navigator didPush',
      hypothesisId: 'H2',
      data: {
        'tag': tag,
        'route': route.settings.name ?? route.runtimeType.toString(),
        'prev': previousRoute?.settings.name ??
            previousRoute?.runtimeType.toString(),
        'isFirst': route.isFirst,
      },
    );
    // #endregion
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // #region agent log
    agentDebugLog(
      location: 'agent_debug_log.dart:didPop',
      message: 'navigator didPop',
      hypothesisId: 'H1',
      data: {
        'tag': tag,
        'route': route.settings.name ?? route.runtimeType.toString(),
        'prev': previousRoute?.settings.name ??
            previousRoute?.runtimeType.toString(),
        'prevIsFirst': previousRoute?.isFirst,
      },
    );
    // #endregion
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // #region agent log
    agentDebugLog(
      location: 'agent_debug_log.dart:didRemove',
      message: 'navigator didRemove',
      hypothesisId: 'H1',
      data: {
        'tag': tag,
        'route': route.settings.name ?? route.runtimeType.toString(),
      },
    );
    // #endregion
  }
}
