import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/core/utils/formatters.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';
import 'package:smartbandhu_admin/core/app_error_mapper.dart';
import 'package:smartbandhu_admin/widgets/maintenance_view.dart';
import 'package:smartbandhu_admin/widgets/stat_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.api});

  final AdminApi api;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardStats? _stats;
  List<RevenuePoint> _revenue = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.getDashboardStats(),
        widget.api.getRevenueChart(days: 30),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as DashboardStats;
        _revenue = results[1] as List<RevenuePoint>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppErrorMapper.message(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null || _stats == null) {
      return MaintenanceView(message: _error, onRetry: _load);
    }

    final stats = _stats!;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Platform overview',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              StatCard(
                label: 'Total Revenue',
                value: currencyFormat.format(stats.totalRevenue),
                hint: 'All time',
                icon: Icons.currency_rupee,
              ),
              StatCard(
                label: 'Revenue Today',
                value: currencyFormat.format(stats.revenueToday),
                hint: 'Today',
                icon: Icons.trending_up,
              ),
              StatCard(
                label: 'Bookings',
                value: '${stats.totalBookings}',
                hint: '${stats.bookingsToday} today',
                icon: Icons.event_note,
              ),
              StatCard(
                label: 'Users',
                value: '${stats.totalUsers}',
                hint: '${stats.newUsersToday} new today',
                icon: Icons.people_outline,
              ),
              StatCard(
                label: 'Pending',
                value: '${stats.pendingBookings}',
                hint: 'Needs action',
                icon: Icons.pending_actions,
              ),
              StatCard(
                label: 'Completed',
                value: '${stats.completedBookings}',
                hint: '${stats.activeVendors} active vendors',
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
          if (_revenue.isNotEmpty) ...[
          const SizedBox(height: 20),
          RepaintBoundary(
            child: _ChartCard(
            title: 'Revenue (30 days)',
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) => Text(
                          '₹${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _revenue.length > 10 ? 5 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _revenue.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('d/M').format(_revenue[index].date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < _revenue.length; i++)
                          FlSpot(i.toDouble(), _revenue[i].revenue),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: _ChartCard(
            title: 'Bookings (30 days)',
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _revenue.length > 10 ? 5 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _revenue.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('d/M').format(_revenue[index].date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < _revenue.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: _revenue[i].bookings.toDouble(),
                            color: AppColors.success,
                            width: 8,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
