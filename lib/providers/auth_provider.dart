import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.apiService, {this.status = AuthStatus.loading}) {
    apiService.onSessionExpired = _handleSessionExpired;
  }

  final ApiService apiService;
  AuthStatus status = AuthStatus.loading;
  Map<String, dynamic>? currentUser;
  String? errorMessage;

  Future<void> initialize() async {
    status = AuthStatus.loading;
    notifyListeners();
    final accessToken = await apiService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      _setUnauthenticated();
      return;
    }

    try {
      await _loadCurrentUser();
    } on ApiException catch (_) {
      if (await apiService.refreshAccessToken()) {
        try {
          await _loadCurrentUser();
        } on ApiException catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    }
  }

  Future<bool> login({required String email, required String password}) async {
    return _authenticate(() => apiService.login(email: email, password: password));
  }

  Future<bool> register({
    required String businessName,
    required String name,
    required String email,
    required String password,
  }) async {
    return _authenticate(
      () => apiService.register(
        data: {
          'business_name': businessName,
          'name': name,
          'email': email,
          'password': password,
        },
      ),
    );
  }

  Future<void> logout() async {
    await apiService.clearTokens();
    currentUser = null;
    _setUnauthenticated();
  }

  Future<void> _loadCurrentUser() async {
    final response = await apiService.me();
    currentUser = _asMap(response.data);
    status = AuthStatus.authenticated;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _authenticate(Future<dynamic> Function() request) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await request();
      final data = _asMap(response.data);
      final accessToken = data['access'] as String?;
      final refreshToken = data['refresh'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw const ApiException(message: 'The API response did not contain login tokens.');
      }
      await apiService.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      currentUser = _asMap(data['user']);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      status = AuthStatus.unauthenticated;
      errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  void _setUnauthenticated() {
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _handleSessionExpired() async {
    currentUser = null;
    _setUnauthenticated();
  }

  Map<String, dynamic> _asMap(Object? value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }
}