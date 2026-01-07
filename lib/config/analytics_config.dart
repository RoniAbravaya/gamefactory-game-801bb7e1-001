/// Analytics configuration for Batch-20260107-122649-puzzle-01
class AnalyticsConfig {
  AnalyticsConfig._();

  /// Game identifier
  static const String gameId = '0fcfceab-debe-4e03-906d-8bc87b6c7c26';
  
  /// App version
  static const String appVersion = '1.0.0';
  
  /// Backend URL for event forwarding
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://api.gamefactory.com',
  );
  
  /// API key for backend authentication
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );
  
  /// Whether to forward events to backend
  static const bool forwardToBackend = true;
  
  /// Debug mode logging
  static const bool debugLogging = bool.fromEnvironment('DEBUG', defaultValue: false);
}
