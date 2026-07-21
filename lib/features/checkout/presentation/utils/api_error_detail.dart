import 'package:dio/dio.dart';

/// Extrae `detail` de errores API (Dio) para mostrar al usuario.
String parseApiErrorDetail(
  Object error, {
  String fallback = 'No se pudo crear el pedido',
}) {
  if (error is DioException) {
    final data = error.response?.data;
    final detail = _extractDetail(data);
    if (detail != null && detail.isNotEmpty) return detail;
  }
  return fallback;
}

String? _extractDetail(Object? data) {
  if (data is String && data.trim().isNotEmpty) return data.trim();
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    if (detail is List && detail.isNotEmpty) {
      final parts = detail.map((e) => e.toString().trim()).where((e) => e.isNotEmpty);
      if (parts.isNotEmpty) return parts.join(' ');
    }
    // DRF field errors: {"field": ["msg"]}
    final messages = <String>[];
    for (final value in data.values) {
      if (value is String && value.trim().isNotEmpty) {
        messages.add(value.trim());
      } else if (value is List) {
        for (final item in value) {
          final text = item.toString().trim();
          if (text.isNotEmpty) messages.add(text);
        }
      }
    }
    if (messages.isNotEmpty) return messages.join(' ');
  }
  return null;
}
