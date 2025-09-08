class AppConstants {
  // App info
  static const String appName = 'Project OData';
  static const String appVersion = '1.0.0';

  // API constants
  static const String odataPath = '/odata/standard.odata/';
  static const String hsPath = '/hs/inventory/';
  static const int connectionTimeout = 30000; // milliseconds
  static const int receiveTimeout = 30000; // milliseconds

  // Storage keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String tokenKey = 'auth_token';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
