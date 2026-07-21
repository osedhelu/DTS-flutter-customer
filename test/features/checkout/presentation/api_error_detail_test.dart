import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dts_customer/features/checkout/presentation/utils/api_error_detail.dart';

void main() {
  test('parseApiErrorDetail_reads_string_detail', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/orders/'),
      response: Response(
        requestOptions: RequestOptions(path: '/orders/'),
        statusCode: 400,
        data: {'detail': 'Método de pago inválido'},
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      parseApiErrorDetail(error),
      'Método de pago inválido',
    );
  });

  test('parseApiErrorDetail_falls_back_when_no_detail', () {
    expect(
      parseApiErrorDetail(Exception('boom'), fallback: 'No se pudo crear el pedido'),
      'No se pudo crear el pedido',
    );
  });
}
