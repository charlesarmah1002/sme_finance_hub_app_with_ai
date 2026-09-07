class AppConfig {
  const AppConfig._();

  static const deployedApiUrl = 'https://cashflow-project-django-api-1.onrender.com/api/';
  static const webDevelopmentUrl = 'https://cashflow-project-django-api-1.onrender.com/api/';
  static const androidEmulatorDevelopmentUrl = 'https://cashflow-project-django-api-1.onrender.com/api/';
  static const configuredApiUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (configuredApiUrl.isNotEmpty) return _withTrailingSlash(configuredApiUrl);
    return deployedApiUrl;
  }

  static String _withTrailingSlash(String value) {
    return value.endsWith('/') ? value : '$value/';
  }
}
