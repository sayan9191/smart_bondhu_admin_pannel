import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smartbandhu_admin/core/app_error_mapper.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/core/utils/formatters.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';
import 'package:smartbandhu_admin/features/dashboard/dashboard_date_range.dart';
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
  DashboardDateRange _range = DashboardDateRange.fromPreset(DashboardDatePreset.last30Days);
  bool _loading = true;
  bool _exporting = false;
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
      final start = _range.apiStart;
      final end = _range.apiEnd;
      final results = await Future.wait([
        widget.api.getDashboardStats(startDate: start, endDate: end),
        widget.api.getRevenueChart(startDate: start, endDate: end),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as DashboardStats;
        _revenue = (results[1] as RevenueChartData).points;
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

  Future<void> _selectPreset(DashboardDatePreset preset) async {
    if (preset == DashboardDatePreset.custom) {
      final picked = await pickCustomDateRange(context, _range);
      if (picked == null || !mounted) return;
      setState(() => _range = picked);
    } else {
      setState(() => _range = DashboardDateRange.fromPreset(preset));
    }
    await _load();
  }

  Future<void> _exportReport() async {
    setState(() => _exporting = true);
    try {
      final csv = await widget.api.exportOrdersReport(
        startDate: _range.apiStart,
        endDate: _range.apiEnd,
      );
      final dir = await getTemporaryDirectory();
      final fileName =
          'smartbondhu_orders_${_range.apiStart}_${_range.apiEnd}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SmartBondhu orders (${_range.subtitle})',
        text: 'Day-wise new orders export',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(e))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  int _labelInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 15) return 2;
    if (count <= 31) return 5;
    if (count <= 60) return 7;
    return 14;
  }

  Widget _bottomLabel(int index, double width) {
    if (index < 0 || index >= _revenue.length) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: width,
      child: Text(
        DateFormat('d/M').format(_revenue[index].date),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 9),
      ),
    );
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
    final interval = _labelInterval(_revenue.length);
    final periodLabel = _range.subtitle;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      periodLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _exporting ? null : _exportReport,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                icon: _exporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_exporting ? 'Export…' : 'Export'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in DashboardDatePreset.values)
                FilterChip(
                  label: Text(DashboardDateRange.fromPreset(preset).label),
                  selected: _range.preset == preset,
                  onSelected: (_) => _selectPreset(preset),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                ),
            ],
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
                label: 'Revenue',
                value: currencyFormat.format(stats.totalRevenue),
                hint: 'In selected period',
                icon: Icons.currency_rupee,
              ),
              StatCard(
                label: 'Revenue Today',
                value: currencyFormat.format(stats.revenueToday),
                hint: 'Live today',
                icon: Icons.trending_up,
              ),
              StatCard(
                label: 'New Orders',
                value: '${stats.totalBookings}',
                hint: '${stats.bookingsToday} today',
                icon: Icons.event_note,
              ),
              StatCard(
                label: 'New Users',
                value: '${stats.totalUsers}',
                hint: '${stats.newUsersToday} today',
                icon: Icons.people_outline,
              ),
              StatCard(
                label: 'Pending',
                value: '${stats.pendingBookings}',
                hint: 'In period',
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
                title: 'Revenue (${_range.label})',
                child: SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (_revenue.length - 1).toDouble(),
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
                            reservedSize: 28,
                            interval: interval.toDouble(),
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _bottomLabel(value.toInt(), 36),
                            ),
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
                title: 'New orders (${_range.label})',
                child: SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: _revenue.map((e) => e.bookings).fold<int>(0, (a, b) => a > b ? a : b).toDouble() + 1,
                      alignment: BarChartAlignment.spaceAround,
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
                            reservedSize: 28,
                            interval: interval.toDouble(),
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _bottomLabel(value.toInt(), 36),
                            ),
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
                                width: _revenue.length > 30 ? 6 : 10,
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
