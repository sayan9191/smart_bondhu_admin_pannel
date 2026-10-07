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
    String? startDate,
    String? endDate,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/admin/bookings',
      queryParameters: {
        'page': page,
        'page_size': 20,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search.isNotEmpty) 'search': search,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
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

  Future<List<AdminCatalogCategory>> getCatalog() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/admin/catalog');
    final categories = response.data!['categories'] as List<dynamic>;
    return categories
        .map((e) => AdminCatalogCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCategory({
    required String name,
    required String slug,
    String? imageUrl,
  }) async {
    await _client.dio.post('/admin/catalog/categories', data: {
      'name': name,
      'slug': slug,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    });
  }

  Future<void> createSubCategory({
    required String categoryId,
    required String name,
    required String slug,
  }) async {
    await _client.dio.post('/admin/catalog/sub-categories', data: {
      'category_id': categoryId,
      'name': name,
      'slug': slug,
    });
  }

  Future<List<AdminBanner>> getBanners() async {
    final response = await _client.dio.get<List<dynamic>>('/admin/banners');
    return (response.data ?? [])
        .map((e) => AdminBanner.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminBanner> createBanner({
    required String title,
    required String imageUrl,
    int sortOrder = 0,
    bool isActive = true,
    String action = 'services',
    String? actionValue,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/admin/banners',
      data: {
        'title': title,
        'image_url': imageUrl,
        'sort_order': sortOrder,
        'is_active': isActive,
        'action': action,
        if (actionValue != null && actionValue.isNotEmpty) 'action_value': actionValue,
      },
    );
    return AdminBanner.fromJson(response.data!);
  }

  Future<AdminBanner> updateBanner(
    String id, {
    String? title,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
    String? action,
    String? actionValue,
  }) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/admin/banners/$id',
      data: {
        if (title != null) 'title': title,
        if (imageUrl != null) 'image_url': imageUrl,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (isActive != null) 'is_active': isActive,
        if (action != null) 'action': action,
        if (actionValue != null) 'action_value': actionValue,
      },
    );
    return AdminBanner.fromJson(response.data!);
  }

  Future<void> deleteBanner(String id) async {
    await _client.dio.delete('/admin/banners/$id');
  }

  Future<void> updateCategory(
    String id, {
    String? name,
    String? description,
    String? imageUrl,
    String? iconUrl,
    bool? isActive,
  }) async {
    await _client.dio.patch('/admin/catalog/categories/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (isActive != null) 'is_active': isActive,
    });
  }

  Future<void> updateSubCategory(
    String id, {
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    await _client.dio.patch('/admin/catalog/sub-categories/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'icon_url': imageUrl,
      if (isActive != null) 'is_active': isActive,
    });
  }

  Future<void> updateService(
    String id, {
    String? name,
    String? description,
    String? imageUrl,
    double? basePrice,
    int? durationMinutes,
    bool? isActive,
  }) async {
    await _client.dio.patch('/admin/catalog/services/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (basePrice != null) 'base_price': basePrice,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (isActive != null) 'is_active': isActive,
    });
  }

  Future<List<WebsiteEnquiry>> getEnquiries() async {
    final response = await _client.dio.get<List<dynamic>>('/admin/enquiries');
    return (response.data ?? [])
        .map((e) => WebsiteEnquiry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WebsiteEnquiry> updateEnquiry(
    String id, {
    String? status,
    String? notes,
  }) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/admin/enquiries/$id',
      data: {
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
      },
    );
    return WebsiteEnquiry.fromJson(response.data!);
  }

  Future<void> createService({
    required String subCategoryId,
    required String name,
    required String slug,
    required double basePrice,
    required int durationMinutes,
    String? description,
    String? imageUrl,
  }) async {
    await _client.dio.post('/admin/catalog/services', data: {
      'sub_category_id': subCategoryId,
      'name': name,
      'slug': slug,
      'base_price': basePrice,
      'duration_minutes': durationMinutes,
      if (description != null && description.isNotEmpty) 'description': description,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    });
  }
}
