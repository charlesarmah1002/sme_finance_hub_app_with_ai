import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class ApiService {
  ApiService({String? baseUrl, Dio? dio, SharedPreferences? preferences})
      : _dio = dio ?? Dio(),
        _refreshDio = Dio(),
        _preferences = preferences,
        baseUrl = _normalizeBaseUrl(baseUrl ?? ApiService.defaultBaseUrl) {
    _dio.options = _dio.options.copyWith(
      baseUrl: this.baseUrl,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    _refreshDio.options = _dio.options.copyWith(baseUrl: this.baseUrl);
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  static const webBaseUrl = AppConfig.webDevelopmentUrl;
  static const androidEmulatorBaseUrl = AppConfig.androidEmulatorDevelopmentUrl;

  static String get defaultBaseUrl => AppConfig.apiBaseUrl;

  final Dio _dio;
  final Dio _refreshDio;
  SharedPreferences? _preferences;
  final String baseUrl;
  Future<void> Function()? onSessionExpired;

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) {
    return _send(() => _dio.get<T>(path, queryParameters: queryParameters));
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _send(() => _dio.post<T>(path, data: data));
  }

  Future<Response<T>> put<T>(String path, {Object? data}) {
    return _send(() => _dio.put<T>(path, data: data));
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return _send(() => _dio.patch<T>(path, data: data));
  }

  Future<Response<T>> delete<T>(String path, {Object? data}) {
    return _send(() => _dio.delete<T>(path, data: data));
  }

  Future<Response<T>> getApiRoot<T>() => get<T>('');

  Future<Response<Map<String, dynamic>>> register(
      {required Map<String, dynamic> data}) {
    return post<Map<String, dynamic>>('auth/register/', data: data);
  }

  Future<Response<Map<String, dynamic>>> login(
      {required String email, required String password}) {
    return post<Map<String, dynamic>>('auth/login/',
        data: {'email': email, 'password': password});
  }

  Future<Response<Map<String, dynamic>>> me() {
    return get<Map<String, dynamic>>('auth/me/');
  }

  Future<Response<Map<String, dynamic>>> dashboardSummary() {
    return get<Map<String, dynamic>>('dashboard/summary/');
  }

  Future<Response<dynamic>> accounts() => get<dynamic>('accounts/');

  Future<Response<Map<String, dynamic>>> createAccount(
      Map<String, dynamic> data) {
    return post<Map<String, dynamic>>('accounts/', data: data);
  }

  Future<Response<Map<String, dynamic>>> updateAccount(
      int id, Map<String, dynamic> data) {
    return put<Map<String, dynamic>>('accounts/$id/', data: data);
  }

  Future<Response<Map<String, dynamic>>> patchAccount(
      int id, Map<String, dynamic> data) {
    return patch<Map<String, dynamic>>('accounts/$id/', data: data);
  }

  Future<void> deleteAccount(int id) async {
    await delete<void>('accounts/$id/');
  }

  Future<Response<dynamic>> categories() => get<dynamic>('categories/');

  Future<Response<Map<String, dynamic>>> createCategory(
      Map<String, dynamic> data) {
    return post<Map<String, dynamic>>('categories/', data: data);
  }

  Future<Response<Map<String, dynamic>>> updateCategory(
      int id, Map<String, dynamic> data) {
    return put<Map<String, dynamic>>('categories/$id/', data: data);
  }

  Future<void> deleteCategory(int id) async {
    await delete<void>('categories/$id/');
  }

  Future<Response<dynamic>> transactions({String? type}) =>
      get<dynamic>('transactions/',
          queryParameters: type == null ? null : {'type': type});

  Future<Response<Map<String, dynamic>>> createTransaction(
      Map<String, dynamic> data) {
    return post<Map<String, dynamic>>('transactions/', data: data);
  }

  Future<Response<Map<String, dynamic>>> updateTransaction(
      int id, Map<String, dynamic> data) {
    return put<Map<String, dynamic>>('transactions/$id/', data: data);
  }

  Future<Response<Map<String, dynamic>>> patchTransaction(
      int id, Map<String, dynamic> data) {
    return patch<Map<String, dynamic>>('transactions/$id/', data: data);
  }

  Future<void> deleteTransaction(int id) async {
    await delete<void>('transactions/$id/');
  }

  Future<Response<dynamic>> cashflowReport() =>
      get<dynamic>('reports/cashflow/');

  Future<Response<dynamic>> categoryReport() =>
      get<dynamic>('reports/by-category/');

  Future<Response<dynamic>> accountReport() =>
      get<dynamic>('reports/by-account/');

  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    final preferences = await _getPreferences();
    await preferences.setString(accessTokenKey, accessToken);
    await preferences.setString(refreshTokenKey, refreshToken);
  }

  Future<String?> getAccessToken() async =>
      (await _getPreferences()).getString(accessTokenKey);

  Future<String?> getRefreshToken() async =>
      (await _getPreferences()).getString(refreshTokenKey);

  Future<void> clearTokens() async {
    final preferences = await _getPreferences();
    await preferences.remove(accessTokenKey);
    await preferences.remove(refreshTokenKey);
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        'auth/refresh/',
        data: {'refresh': refreshToken},
      );
      final accessToken = response.data?['access'] as String?;
      if (accessToken == null || accessToken.isEmpty) return false;
      await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value : '$value/';
  }

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.service);

  final ApiService service;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await service.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException error, ErrorInterceptorHandler handler) async {
    final alreadyRetried = error.requestOptions.extra['authRetry'] == true;
    if (error.response?.statusCode != 401 ||
        alreadyRetried ||
        error.requestOptions.path == 'auth/refresh/') {
      handler.next(error);
      return;
    }

    final refreshed = await service.refreshAccessToken();
    if (!refreshed) {
      await service.clearTokens();
      await service.onSessionExpired?.call();
      handler.next(error);
      return;
    }

    final request = error.requestOptions;
    request.extra['authRetry'] = true;
    request.headers['Authorization'] =
        'Bearer ${await service.getAccessToken()}';
    try {
      handler.resolve(await service._dio.fetch(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final detail = _errorDetail(responseData);
    final message = detail != null && detail.isNotEmpty
        ? detail
        : statusCode == null
            ? 'Unable to communicate with the API.'
            : 'API request failed with status $statusCode.';

    return ApiException(message: message, statusCode: statusCode);
  }

  static String? _errorDetail(Object? data) {
    if (data is Map<String, dynamic>) {
      final values = data.entries.map((entry) {
        final value = entry.value is List
            ? (entry.value as List).join(', ')
            : entry.value;
        return '${entry.key}: $value';
      }).join('\n');
      return values.isEmpty ? null : values;
    }
    final text = data?.toString();
    return text == null || text.isEmpty ? null : text;
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
