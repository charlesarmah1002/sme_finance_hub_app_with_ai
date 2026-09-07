class AppConfig {
  const AppConfig._();

  static const deployedApiUrl = 'https://cashflow-project-django-api-1.onrender.com/api/';
  static const webDevelopmentUrl = 'http://localhost:8000/api/';
  static const androidEmulatorDevelopmentUrl = 'http://10.0.2.2:8000/api/';
  static const configuredApiUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (configuredApiUrl.isNotEmpty) return _withTrailingSlash(configuredApiUrl);
    return deployedApiUrl;
  }

  static String _withTrailingSlash(String value) {
    return value.endsWith('/') ? value : '$value/';
  }
}
