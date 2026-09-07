import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  late HttpServer server;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      if (request.uri.path == '/api/') {
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'status': 'ok'}))
          ..close();
        return;
      }

      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
    });
  });

  tearDown(() => server.close());

  test('GET /api/ receives a JSON response', () async {
    final service = ApiService(baseUrl: 'http://127.0.0.1:${server.port}/api');

    final response = await service.getApiRoot<Map<String, dynamic>>();

    expect(response.data, {'status': 'ok'});
  });

  test('HTTP errors become ApiException instances', () async {
    final service = ApiService(baseUrl: 'http://127.0.0.1:${server.port}/api');

    expect(
      () => service.get<void>('missing'),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status code', 404),
      ),
    );
  });
}