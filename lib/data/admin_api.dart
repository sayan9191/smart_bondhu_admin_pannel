import 'package:smartbandhu_admin/core/network/api_client.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';

class AdminApi {
  AdminApi(this._client);

  final ApiClient _client;

  Future<DashboardStats> getDashboardStats() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/admin/dashboard/stats');
    return DashboardStats.fromJson(response.data!);
  }

  Future<List<RevenuePoint>> getRevenueChart({int days = 30}) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/admin/dashboard/revenue',
      queryParameters: {'days': days},
    );
    final points = response.data!['points'] as List<dynamic>;
    return points.map((e) => RevenuePoint.fromJson(e as Map<String, dynamic>)).toList();
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
}
