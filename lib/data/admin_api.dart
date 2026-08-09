import 'package:smartbandhu_admin/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';

class AdminApi {
  AdminApi(this._client);

  final ApiClient _client;

  Future<DashboardStats> getDashboardStats({
    String? startDate,
    String? endDate,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/admin/dashboard/stats',
      queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return DashboardStats.fromJson(response.data!);
  }

  Future<RevenueChartData> getRevenueChart({
    int? days,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/admin/dashboard/revenue',
      queryParameters: {
        if (days != null) 'days': days,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    final data = response.data!;
    final points = (data['points'] as List<dynamic>)
        .map((e) => RevenuePoint.fromJson(e as Map<String, dynamic>))
        .toList();
    return RevenueChartData(
      points: points,
      periodStart: data['period_start'] != null
          ? DateTime.parse(data['period_start'] as String)
          : null,
      periodEnd: data['period_end'] != null
          ? DateTime.parse(data['period_end'] as String)
          : null,
    );
  }

  Future<String> exportOrdersReport({
    String? startDate,
    String? endDate,
  }) async {
    final response = await _client.dio.get<String>(
      '/admin/dashboard/export',
      queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  Future<Paginated<AdminUser>> getUsers({int page = 1, String search = ''}) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: {
        'page': page,
        'page_size': 20,
        if (search.isNotEmpty) 'search': search,
      },
    );
    return Paginated.fromJson(response.data!, AdminUser.fromJson);
  }

  Future<AdminUser> updateUser(String userId, {bool? isActive, String? role}) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/admin/users/$userId',
      data: {
        if (isActive != null) 'is_active': isActive,
        if (role != null) 'role': role,
      },
    );
    return AdminUser.fromJson(response.data!);
  }

  Future<Paginated<AdminBooking>> getBookings({
    int page = 1,
    String? status,
    String search = '',
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/admin/bookings',
      queryParameters: {
        'page': page,
        'page_size': 20,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search.isNotEmpty) 'search': search,
      },
    );
    return Paginated.fromJson(response.data!, AdminBooking.fromJson);
  }

  Future<AdminBooking> updateBookingStatus(
    String bookingId,
    String status, {
    String? notes,
  }) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/admin/bookings/$bookingId/status',
      data: {
        'status': status,
        if (notes != null) 'notes': notes,
      },
    );
    return AdminBooking.fromJson(response.data!);
  }

  Future<AppSettings> getAppSettings() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/admin/settings');
    return AppSettings.fromJson(response.data!);
  }

  Future<AppSettings> updateAppSettings(AppSettings settings) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/admin/settings',
      data: settings.toUpdateJson(),
    );
    return AppSettings.fromJson(response.data!);
  }

  Future<BroadcastResult> broadcastNotification({
    required String title,
    required String body,
    String notificationType = 'promotion',
    String? screen,
    String? code,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/admin/notifications/broadcast',
      data: {
        'title': title,
        'body': body,
        'notification_type': notificationType,
        if (screen != null) 'screen': screen,
        if (code != null) 'code': code,
      },
    );
    return BroadcastResult.fromJson(response.data!);
  }
}
