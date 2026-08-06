import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiHostResolver {
  static const Duration _probeTimeout = Duration(milliseconds: 900);

  static Future<String> resolve({
    required List<String> hostCandidates,
    int port = 8000,
  }) async {
    if (hostCandidates.isEmpty) {
      return 'http://127.0.0.1:$port/api/v1';
    }

    for (final host in hostCandidates) {
      if (await _isReachable(host, port)) {
        final url = 'http://$host:$port/api/v1';
        if (kDebugMode) debugPrint('SmartBondhu API → $url');
        return url;
      }
    }

    return 'http://${hostCandidates.first}:$port/api/v1';
  }

  static Future<bool> _isReachable(String host, int port) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = _probeTimeout;
      final request = await client
          .getUrl(Uri.parse('http://$host:$port/health'))
          .timeout(_probeTimeout);
      final response = await request.close().timeout(_probeTimeout);
      await response.drain().timeout(_probeTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client?.close(force: true);
    }
  }
}
