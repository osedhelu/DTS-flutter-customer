import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/env.dart';
import '../../domain/entities/tracking_location_update.dart';

/// Abstracción de la conexión WS (permite fake en tests).
abstract class TrackingWsConnection {
  Stream<dynamic> get messages;
  Future<void> close();
}

typedef TrackingWsConnectionFactory = TrackingWsConnection Function(Uri uri);

class WebSocketTrackingConnection implements TrackingWsConnection {
  WebSocketTrackingConnection(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get messages => _channel.stream;

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

/// Datasource WebSocket para tracking en vivo — T5.3.1.
///
/// Ruta: `wss://host/ws/orders/{id}/tracking/?token=<jwt>`
class TrackingWsDataSource {
  TrackingWsDataSource({
    String? wsBaseUrl,
    TrackingWsConnectionFactory? connectionFactory,
  })  : _wsBaseUrl = wsBaseUrl ?? EnvConfig.wsBaseUrl,
        _connectionFactory =
            connectionFactory ?? _defaultConnectionFactory;

  final String _wsBaseUrl;
  final TrackingWsConnectionFactory _connectionFactory;
  TrackingWsConnection? _active;

  static TrackingWsConnection _defaultConnectionFactory(Uri uri) {
    return WebSocketTrackingConnection(WebSocketChannel.connect(uri));
  }

  /// URI pública (útil en tests).
  Uri buildUri({required int orderId, required String accessToken}) {
    final base = _wsBaseUrl.endsWith('/')
        ? _wsBaseUrl.substring(0, _wsBaseUrl.length - 1)
        : _wsBaseUrl;
    return Uri.parse('$base/ws/orders/$orderId/tracking/').replace(
      queryParameters: {'token': accessToken},
    );
  }

  /// Escucha actualizaciones `type: location` del room del pedido.
  Stream<TrackingLocationUpdate> watchLocations({
    required int orderId,
    required String accessToken,
  }) {
    final uri = buildUri(orderId: orderId, accessToken: accessToken);
    final connection = _connectionFactory(uri);
    _active = connection;

    return connection.messages.transform(
      StreamTransformer<dynamic, TrackingLocationUpdate>.fromHandlers(
        handleData: (event, sink) {
          final update = _parseLocation(event);
          if (update != null) sink.add(update);
        },
        handleError: (error, stackTrace, sink) {
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) => sink.close(),
      ),
    );
  }

  Future<void> disconnect() async {
    final connection = _active;
    _active = null;
    await connection?.close();
  }

  TrackingLocationUpdate? _parseLocation(dynamic event) {
    try {
      final Map<String, dynamic> json;
      if (event is String) {
        json = jsonDecode(event) as Map<String, dynamic>;
      } else if (event is Map<String, dynamic>) {
        json = event;
      } else {
        return null;
      }
      if (json['type'] != 'location') return null;
      return TrackingLocationUpdate.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
