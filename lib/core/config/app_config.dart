import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'SmartBondhu Admin';

  /// Deployed API. Override with --dart-define=API_BASE_URL=...
  static const String remoteApiBaseUrl =
      'https://eal5zocqpln7howaxskjjvdmcm0asgdb.lambda-url.ap-south-1.on.aws/api/v1';

  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String? _resolvedApiBaseUrl;

  /// Synchronous fast path — use before [runApp] when dart-defines are set.
  static void initSync() {
    if (_resolvedApiBaseUrl != null) return;
    _resolvedApiBaseUrl =
        _envApiBaseUrl.isNotEmpty ? _envApiBaseUrl : remoteApiBaseUrl;
    if (kDebugMode) debugPrint('SmartBondhu Admin API → $_resolvedApiBaseUrl');
  }

  static Future<void> init() async {
    initSync();
  }

  static String get apiBaseUrl {
    assert(_resolvedApiBaseUrl != null, 'Call AppConfig.init() first');
    return _resolvedApiBaseUrl!;
  }
}
