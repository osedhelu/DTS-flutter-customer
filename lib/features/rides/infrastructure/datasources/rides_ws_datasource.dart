import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/env.dart';
import '../../domain/entities/ride_tracking_update.dart';

/// Abstracción de la conexión WS (permite fake en tests).
abstract class RidesWsConnection {
  Stream<dynamic> get messages;
  Future<void> close();
}

typedef RidesWsConnectionFactory = RidesWsConnection Function(Uri uri);

class WebSocketRidesConnection implements RidesWsConnection {
  WebSocketRidesConnection(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get messages => _channel.stream;

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

/// Datasource WebSocket para tracking de viajes en vivo.
///
/// Reutiliza el room de tracking de pedidos del backend (los viajes son
/// `Order` con `order_type=RIDE`): `wss://host/ws/orders/{id}/tracking/?token=`.
class RidesWsDataSource {
  RidesWsDataSource({
    String? wsBaseUrl,
    RidesWsConnectionFactory? connectionFactory,
  })  : _wsBaseUrl = wsBaseUrl ?? EnvConfig.wsBaseUrl,
        _connectionFactory = connectionFactory ?? _defaultConnectionFactory;

  final String _wsBaseUrl;
  final RidesWsConnectionFactory _connectionFactory;
  RidesWsConnection? _active;
  double? _lastLat;
  double? _lastLng;

  static RidesWsConnection _defaultConnectionFactory(Uri uri) {
    return WebSocketRidesConnection(WebSocketChannel.connect(uri));
  }

  Uri buildUri({required int rideId, required String accessToken}) {
    final base = _wsBaseUrl.endsWith('/')
        ? _wsBaseUrl.substring(0, _wsBaseUrl.length - 1)
        : _wsBaseUrl;
    final token = Uri.encodeQueryComponent(accessToken);
    return EnvConfig.normalizeWsUri(
      Uri.parse('$base/ws/orders/$rideId/tracking/?token=$token'),
    );
  }

  /// Escucha actualizaciones del viaje:
  /// - `type: location` → punto GPS del conductor.
  /// - `type: order_status` → cambio de estado (conserva posiciones previas).
  Stream<RideTrackingUpdate> watchRide({
    required int rideId,
    required String accessToken,
  }) {
    final uri = buildUri(rideId: rideId, accessToken: accessToken);
    final connection = _connectionFactory(uri);
    _active = connection;

    return connection.messages.transform(
      StreamTransformer<dynamic, RideTrackingUpdate>.fromHandlers(
        handleData: (event, sink) {
          final json = _tryDecode(event);
          if (json == null) return;

          switch (json['type']) {
            case 'location':
              final update = RideTrackingUpdate.fromJson(json);
              _lastLat = update.driverLatitude;
              _lastLng = update.driverLongitude;
              sink.add(update);
            case 'order_status':
              sink.add(
                RideTrackingUpdate(
                  rideId: (json['order_id'] as num?)?.toInt() ?? rideId,
                  status: RideTrackingUpdate.fromJson(json).status,
                  driverLatitude: _lastLat,
                  driverLongitude: _lastLng,
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
