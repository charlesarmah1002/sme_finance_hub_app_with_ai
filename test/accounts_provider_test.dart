import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/providers/accounts_provider.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  late HttpServer server;
  var listCalls = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    listCalls = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      if (path == '/api/accounts/' && request.method == 'GET') {
        listCalls++;
        _json(request.response, {'results': [_accountJson]});
        return;
      }
      if (path == '/api/accounts/' && request.method == 'POST') {
        await utf8.decoder.bind(request).join();
        _json(request.response, _accountJson);
        return;
      }
      if (path == '/api/accounts/1/' && request.method == 'DELETE') {
        request.response..statusCode = HttpStatus.noContent..close();
        return;
      }
      if (path == '/api/accounts/1/' && (request.method == 'PUT' || request.method == 'PATCH')) {
        await utf8.decoder.bind(request).join();
        _json(request.response, _accountJson);
        return;
      }
      _json(request.response, _accountJson);
    });
  });

  tearDown(() => server.close());

  test('loads accounts and refreshes after CRUD mutations', () async {
    final provider = AccountsProvider(ApiService(baseUrl: 'http://127.0.0.1:${server.port}/api'));

    await provider.load();
    expect(provider.accounts.single.name, 'Operating account');
    expect(provider.accounts.single.isActive, isTrue);
    expect(listCalls, 1);

    expect(await provider.create({'name': 'Savings', 'balance': 10}), isTrue);
    expect(await provider.update(1, {'name': 'Updated'}), isTrue);
    expect(await provider.deactivate(1), isTrue);
    expect(await provider.delete(1), isTrue);
    expect(listCalls, 5);
    expect(provider.errorMessage, isNull);
  });
}

const _accountJson = {
  'id': 1,
  'name': 'Operating account',
  'account_type': 'Bank',
  'balance': '1250.50',
  'is_active': true,
};

void _json(HttpResponse response, Object body) {
  response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}