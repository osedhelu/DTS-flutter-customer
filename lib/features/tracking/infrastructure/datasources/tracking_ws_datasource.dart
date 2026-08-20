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
        _connectionFactory = connectionFactory ?? _defaultConnectionFactory;

  final String _wsBaseUrl;
  final TrackingWsConnectionFactory _connectionFactory;
  TrackingWsConnection? _active;
  double? _lastLat;
  double? _lastLng;

  static TrackingWsConnection _defaultConnectionFactory(Uri uri) {
    return WebSocketTrackingConnection(WebSocketChannel.connect(uri));
  }

  /// URI pública (útil en tests). Evita `port == 0` / `Uri.replace` roto en wss.
  Uri buildUri({required int orderId, required String accessToken}) {
    final base = _wsBaseUrl.endsWith('/')
        ? _wsBaseUrl.substring(0, _wsBaseUrl.length - 1)
        : _wsBaseUrl;
    final token = Uri.encodeQueryComponent(accessToken);
    return EnvConfig.normalizeWsUri(
      Uri.parse('$base/ws/orders/$orderId/tracking/?token=$token'),
    );
  }

  /// Escucha actualizaciones del room del pedido:
  /// - `type: location` → punto GPS con ruta/ETA.
  /// - `type: order_status` → cambio de estado (posiciones previas conocidas).
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
          final json = _tryDecode(event);
          if (json == null) return;

          switch (json['type']) {
            case 'location':
              final update = TrackingLocationUpdate.fromJson(json);
              _lastLat = update.latitude;
              _lastLng = update.longitude;
              sink.add(update);
            case 'order_status':
              sink.add(
                TrackingLocationUpdate(
                  orderId: (json['order_id'] as num?)?.toInt() ?? orderId,
                  orderStatus: json['status']?.toString(),
                  latitude: _lastLat,
                  longitude: _lastLng,
                ),
              );
            default:
              break;
          }
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
    _lastLat = null;
    _lastLng = null;
    await connection?.close();
  }

  Map<String, dynamic>? _tryDecode(dynamic event) {
    try {
      if (event is String) {
        final decoded = jsonDecode(event);
        if (decoded is Map<String, dynamic>) return decoded;
      } else if (event is Map<String, dynamic>) {
        return event;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
