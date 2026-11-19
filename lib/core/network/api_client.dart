import 'package:dio/dio.dart';
import 'package:smartbandhu_admin/core/config/app_config.dart';

class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        // The backend is serverless (AWS Lambda). A cold start after idle can
        // take several seconds, so the timeouts are generous enough to wait it
        // out instead of failing with "temporarily unavailable".
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(_ColdStartRetryInterceptor(_dio));
  }

  late final Dio _dio;
  Dio get dio => _dio;
}

/// Retries a failed GET once, after a short delay.
///
/// The backend runs on AWS Lambda. After it has been idle the first request
/// triggers a cold start that can be slow or briefly return a 5xx while the
/// function boots. Retrying once makes that invisible to the user instead of
/// showing a "temporarily unavailable" message. Only idempotent methods
/// (GET, PATCH, DELETE) are retried, so a create (POST) is never sent twice.
class _ColdStartRetryInterceptor extends Interceptor {
  _ColdStartRetryInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final alreadyRetried = options.extra['coldStartRetried'] == true;

    if (!alreadyRetried && _shouldRetry(err)) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      options.extra['coldStartRetried'] = true;
      try {
        final response = await _dio.fetch<dynamic>(options);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    const retriable = {'GET', 'PATCH', 'DELETE'};
    if (!retriable.contains(err.requestOptions.method.toUpperCase())) {
      return false;
    }
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        final status = err.response?.statusCode;
        return status != null && status >= 500;
    }
  }
}
