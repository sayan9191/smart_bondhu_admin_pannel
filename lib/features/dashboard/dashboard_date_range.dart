import 'package:flutter/material.dart';

enum DashboardDatePreset {
  today,
  tomorrow,
  last15Days,
  last30Days,
  last60Days,
  last90Days,
  custom,
}

class DashboardDateRange {
  const DashboardDateRange({
    required this.preset,
    required this.start,
    required this.end,
  });

  final DashboardDatePreset preset;
  final DateTime start;
  final DateTime end;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DashboardDateRange fromPreset(DashboardDatePreset preset) {
    final today = _dateOnly(DateTime.now());
    switch (preset) {
      case DashboardDatePreset.today:
        return DashboardDateRange(preset: preset, start: today, end: today);
      case DashboardDatePreset.tomorrow:
        final tomorrow = today.add(const Duration(days: 1));
        return DashboardDateRange(preset: preset, start: tomorrow, end: tomorrow);
      case DashboardDatePreset.last15Days:
        return DashboardDateRange(
          preset: preset,
          start: today.subtract(const Duration(days: 14)),
          end: today,
        );
      case DashboardDatePreset.last30Days:
        return DashboardDateRange(
          preset: preset,
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case DashboardDatePreset.last60Days:
        return DashboardDateRange(
          preset: preset,
          start: today.subtract(const Duration(days: 59)),
          end: today,
        );
      case DashboardDatePreset.last90Days:
        return DashboardDateRange(
          preset: preset,
          start: today.subtract(const Duration(days: 89)),
          end: today,
        );
      case DashboardDatePreset.custom:
        return DashboardDateRange(preset: preset, start: today, end: today);
    }
  }

  String get apiStart => _formatApiDate(start);
  String get apiEnd => _formatApiDate(end);

  String get label {
    switch (preset) {
      case DashboardDatePreset.today:
        return 'Today';
      case DashboardDatePreset.tomorrow:
        return 'Tomorrow';
      case DashboardDatePreset.last15Days:
        return '15 days';
      case DashboardDatePreset.last30Days:
        return '30 days';
      case DashboardDatePreset.last60Days:
        return '60 days';
      case DashboardDatePreset.last90Days:
        return '90 days';
      case DashboardDatePreset.custom:
        return 'Custom';
    }
  }

  String get subtitle {
    if (start == end) {
      return _formatDisplayDate(start);
    }
    return '${_formatDisplayDate(start)} – ${_formatDisplayDate(end)}';
  }

  DashboardDateRange copyWith({DateTime? start, DateTime? end}) {
    return DashboardDateRange(
      preset: preset,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  static String _formatApiDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatDisplayDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

Future<DashboardDateRange?> pickCustomDateRange(
  BuildContext context,
  DashboardDateRange current,
) async {
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    initialDateRange: DateTimeRange(start: current.start, end: current.end),
  );
  if (picked == null) return null;
  return DashboardDateRange(
    preset: DashboardDatePreset.custom,
    start: DashboardDateRange._dateOnly(picked.start),
    end: DashboardDateRange._dateOnly(picked.end),
  );
}
