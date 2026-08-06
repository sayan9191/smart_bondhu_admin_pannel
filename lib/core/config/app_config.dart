import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'SmartBondhu Admin';

  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _devLanIp = String.fromEnvironment('DEV_LAN_IP');

  static String? _resolvedApiBaseUrl;

  static Future<void> init() async {
    if (_envApiBaseUrl.isNotEmpty) {
      _resolvedApiBaseUrl = _envApiBaseUrl;
      return;
    }

    if (kIsWeb) {
      _resolvedApiBaseUrl = 'http://localhost:8000/api/v1';
      return;
    }

    if (Platform.isAndroid) {
      _resolvedApiBaseUrl = await _resolveAndroidApiBaseUrl();
      return;
    }

    _resolvedApiBaseUrl = 'http://localhost:8000/api/v1';
  }

  static Future<String> _resolveAndroidApiBaseUrl() async {
    if (_devLanIp.isNotEmpty) {
      return 'http://$_devLanIp:8000/api/v1';
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (!androidInfo.isPhysicalDevice) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    return 'http://127.0.0.1:8000/api/v1';
  }

  static String get apiBaseUrl {
    assert(_resolvedApiBaseUrl != null, 'Call AppConfig.init() first');
    return _resolvedApiBaseUrl!;
  }
}
