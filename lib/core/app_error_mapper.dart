import 'package:dio/dio.dart';

class AppErrorMapper {
  AppErrorMapper._();

  static const maintenanceTitle = 'Under maintenance';
  static const maintenanceMessage =
      'Admin dashboard is temporarily unavailable. Please try again in a few minutes.';

  static const offlineMessage = 'No internet connection. Check your network and try again.';

  static String message(dynamic error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == null || status >= 500 || status == 503) return maintenanceMessage;
      if (_isOffline(error)) return offlineMessage;
      return maintenanceMessage;
    }
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Connection refused')) {
      return offlineMessage;
    }
    return maintenanceMessage;
  }

  static bool _isOffline(DioException error) =>
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.connectionError;
}
