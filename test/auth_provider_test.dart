import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/providers/auth_provider.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  late HttpServer server;
  late int meCalls;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    meCalls = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      if (path == '/api/auth/login/' || path == '/api/auth/register/') {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        if (path.endsWith('login/') && data['email'] == 'wrong@example.com') {
          _writeJson(request.response, HttpStatus.unauthorized, {'detail': 'Invalid credentials'});
          return;
        }
        _writeJson(request.response, HttpStatus.ok, _tokens);
        return;
      }
      if (path == '/api/auth/me/') {
        meCalls++;
        final authorization = request.headers.value(HttpHeaders.authorizationHeader);
        if (authorization == 'Bearer expired') {
          _writeJson(request.response, HttpStatus.unauthorized, {'detail': 'Expired'});
        } else {
          _writeJson(request.response, HttpStatus.ok, {'id': 1, 'email': 'owner@example.com'});
        }
        return;
      }
      if (path == '/api/auth/refresh/') {
        _writeJson(request.response, HttpStatus.ok, {'access': 'fresh-access'});
        return;
      }
      _writeJson(request.response, HttpStatus.unauthorized, {'detail': 'Invalid credentials'});
    });
  });

  tearDown(() => server.close());

  test('login stores tokens and logout clears them', () async {
    final auth = AuthProvider(_service(server.port));

    expect(await auth.login(email: 'owner@example.com', password: 'password'), isTrue);
    expect(auth.status, AuthStatus.authenticated);
    expect(await auth.apiService.getAccessToken(), 'access-token');

    await auth.logout();
    expect(auth.status, AuthStatus.unauthenticated);
    expect(await auth.apiService.getAccessToken(), isNull);
  });

  test('registration stores tokens', () async {
    final auth = AuthProvider(_service(server.port));

    expect(
      await auth.register(
        businessName: 'Example Ltd',
        name: 'Owner',
        email: 'owner@example.com',
        password: 'password',
      ),
      isTrue,
    );
    expect(auth.currentUser?['email'], 'owner@example.com');
  });

  test('startup restores an expired access token through refresh', () async {
    SharedPreferences.setMockInitialValues({'access_token': 'expired', 'refresh_token': 'refresh-token'});
    final auth = AuthProvider(_service(server.port));

    await auth.initialize();

    expect(auth.status, AuthStatus.authenticated);
    expect(await auth.apiService.getAccessToken(), 'fresh-access');
    expect(meCalls, 2);
  });

  test('invalid credentials leave the user unauthenticated', () async {
    final auth = AuthProvider(_service(server.port));

    final result = await auth.login(email: 'wrong@example.com', password: 'wrong');

    expect(result, isFalse);
    expect(auth.status, AuthStatus.unauthenticated);
  });
}

const _tokens = {
  'access': 'access-token',
  'refresh': 'refresh-token',
  'user': {'id': 1, 'email': 'owner@example.com'},
};

ApiService _service(int port) => ApiService(baseUrl: 'http://127.0.0.1:$port/api');

void _writeJson(HttpResponse response, int statusCode, Object body) {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}