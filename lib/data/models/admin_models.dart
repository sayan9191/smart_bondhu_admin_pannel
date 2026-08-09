class DashboardStats {
  const DashboardStats({
    required this.totalUsers,
    required this.totalBookings,
    required this.bookingsToday,
    required this.newUsersToday,
    required this.pendingBookings,
    required this.completedBookings,
    required this.totalRevenue,
    required this.revenueToday,
    required this.activeVendors,
    this.periodStart,
    this.periodEnd,
  });

  final int totalUsers;
  final int totalBookings;
  final int bookingsToday;
  final int newUsersToday;
  final int pendingBookings;
  final int completedBookings;
  final double totalRevenue;
  final double revenueToday;
  final int activeVendors;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['total_users'] as int,
      totalBookings: json['total_bookings'] as int,
      bookingsToday: json['bookings_today'] as int,
      newUsersToday: json['new_users_today'] as int,
      pendingBookings: json['pending_bookings'] as int,
      completedBookings: json['completed_bookings'] as int,
      totalRevenue: double.parse(json['total_revenue'].toString()),
      revenueToday: double.parse(json['revenue_today'].toString()),
      activeVendors: json['active_vendors'] as int,
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'] as String)
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.parse(json['period_end'] as String)
          : null,
    );
  }
}

class RevenueChartData {
  const RevenueChartData({
    required this.points,
    this.periodStart,
    this.periodEnd,
  });

  final List<RevenuePoint> points;
  final DateTime? periodStart;
  final DateTime? periodEnd;
}

class RevenuePoint {
  const RevenuePoint({
    required this.date,
    required this.revenue,
    required this.bookings,
  });

  final DateTime date;
  final double revenue;
  final int bookings;

  factory RevenuePoint.fromJson(Map<String, dynamic> json) {
    return RevenuePoint(
      date: DateTime.parse(json['date'] as String),
      revenue: double.parse(json['revenue'].toString()),
      bookings: json['bookings'] as int,
    );
  }
}

class Paginated<T> {
  const Paginated({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return Paginated(
      items: (json['items'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.bookingsCount,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final String role;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final int bookingsCount;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      isVerified: json['is_verified'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      bookingsCount: json['bookings_count'] as int,
    );
  }
}

class AdminBooking {
  const AdminBooking({
    required this.id,
    required this.bookingNumber,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.serviceName,
    required this.addressSummary,
    required this.scheduledAt,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
  });

  final String id;
  final String bookingNumber;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String serviceName;
  final String? addressSummary;
  final DateTime scheduledAt;
  final String status;
  final double totalAmount;
  final DateTime createdAt;

  factory AdminBooking.fromJson(Map<String, dynamic> json) {
    return AdminBooking(
      id: json['id'] as String,
      bookingNumber: json['booking_number'] as String,
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      serviceName: json['service_name'] as String,
      addressSummary: json['address_summary'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: json['status'] as String,
      totalAmount: double.parse(json['total_amount'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.forceUpdate,
    required this.minAndroidVersion,
    required this.minIosVersion,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool forceUpdate;
  final String minAndroidVersion;
  final String minIosVersion;
  final String androidStoreUrl;
  final String iosStoreUrl;

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        maintenanceMode: json['maintenance_mode'] as bool? ?? false,
        maintenanceMessage: json['maintenance_message'] as String? ?? '',
        forceUpdate: json['force_update'] as bool? ?? false,
        minAndroidVersion: json['min_android_version'] as String? ?? '1.0.0',
        minIosVersion: json['min_ios_version'] as String? ?? '1.0.0',
        androidStoreUrl: json['android_store_url'] as String? ?? '',
        iosStoreUrl: json['ios_store_url'] as String? ?? '',
      );

  Map<String, dynamic> toUpdateJson() => {
        'maintenance_mode': maintenanceMode,
        'maintenance_message': maintenanceMessage,
        'force_update': forceUpdate,
        'min_android_version': minAndroidVersion,
        'min_ios_version': minIosVersion,
      };
}

class BroadcastResult {
  const BroadcastResult({required this.message, required this.recipients});

  final String message;
  final int recipients;

  factory BroadcastResult.fromJson(Map<String, dynamic> json) => BroadcastResult(
        message: json['message'] as String? ?? 'Sent',
        recipients: json['recipients'] as int? ?? 0,
      );
}

class AdminCatalogService {
  const AdminCatalogService({
    required this.id,
    required this.name,
    required this.slug,
    required this.basePrice,
    required this.durationMinutes,
    required this.isActive,
  });

  final String id;
  final String name;
  final String slug;
  final double basePrice;
  final int durationMinutes;
  final bool isActive;

  factory AdminCatalogService.fromJson(Map<String, dynamic> json) => AdminCatalogService(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        basePrice: double.parse(json['base_price'].toString()),
        durationMinutes: json['duration_minutes'] as int,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class AdminCatalogSubCategory {
  const AdminCatalogSubCategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.services,
  });

  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final List<AdminCatalogService> services;

  factory AdminCatalogSubCategory.fromJson(Map<String, dynamic> json) => AdminCatalogSubCategory(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        services: (json['services'] as List<dynamic>? ?? [])
            .map((e) => AdminCatalogService.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AdminCatalogCategory {
  const AdminCatalogCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.subCategories,
  });

  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final List<AdminCatalogSubCategory> subCategories;

  factory AdminCatalogCategory.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>;
    final subs = (json['sub_categories'] as List<dynamic>? ?? [])
        .map((e) => AdminCatalogSubCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return AdminCatalogCategory(
      id: category['id'] as String,
      name: category['name'] as String,
      slug: category['slug'] as String,
      isActive: category['is_active'] as bool? ?? true,
      subCategories: subs,
    );
  }
}
