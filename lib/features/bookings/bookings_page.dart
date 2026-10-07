import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbandhu_admin/core/app_error_mapper.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/core/utils/formatters.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';
import 'package:smartbandhu_admin/widgets/maintenance_view.dart';
import 'package:smartbandhu_admin/widgets/status_badge.dart';

const _statuses = [
  'pending',
  'confirmed',
  'assigned',
  'in_progress',
  'completed',
  'cancelled',
  'refunded',
];

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key, required this.api});

  final AdminApi api;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  Paginated<AdminBooking>? _data;
  int _page = 1;
  String _statusFilter = '';
  String _search = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _loading = true;
  String? _error;
  String? _updatingId;

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
      final data = await widget.api.getBookings(
        page: _page,
        status: _statusFilter.isEmpty ? null : _statusFilter,
        search: _search,
        startDate: _fromDate == null ? null : DateFormat('yyyy-MM-dd').format(_fromDate!),
        endDate: _toDate == null ? null : DateFormat('yyyy-MM-dd').format(_toDate!),
      );
      if (!mounted) return;
      setState(() {
        _data = data;
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

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _fromDate : _toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    _page = 1;
    if (isStart) {
      _fromDate = picked;
    } else {
      _toDate = picked;
    }
    await _load();
  }

  Future<void> _updateStatus(AdminBooking booking, String status) async {
    setState(() => _updatingId = booking.id);
    try {
      await widget.api.updateBookingStatus(booking.id, status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(e))),
      );
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search booking #, name…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (value) {
                  _page = 1;
                  _search = value.trim();
                  _load();
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: true),
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(_fromDate == null ? 'From date' : dateFormat.format(_fromDate!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: false),
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(_toDate == null ? 'To date' : dateFormat.format(_toDate!)),
                    ),
                  ),
                  if (_fromDate != null || _toDate != null)
                    IconButton(
                      tooltip: 'Clear dates',
                      onPressed: () {
                        _page = 1;
                        _fromDate = null;
                        _toDate = null;
                        _load();
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _statusFilter.isEmpty,
                        onSelected: (_) {
                          _page = 1;
                          _statusFilter = '';
                          _load();
                        },
                      ),
                    ),
                    ..._statuses.map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(formatStatus(status)),
                          selected: _statusFilter == status,
                          onSelected: (_) {
                            _page = 1;
                            _statusFilter = status;
                            _load();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Expanded(child: MaintenanceView(message: _error, onRetry: _load))
        else
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _data == null || _data!.items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No bookings found')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _data!.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final booking = _data!.items[index];
                            return _BookingTile(
                              booking: booking,
                              updating: _updatingId == booking.id,
                              onStatusChanged: (status) => _updateStatus(booking, status),
                            );
                          },
                        ),
                ),
        ),
        if (_data != null && _data!.totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _page > 1
                      ? () {
                          _page--;
                          _load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page $_page of ${_data!.totalPages}'),
                IconButton(
                  onPressed: _page < _data!.totalPages
                      ? () {
                          _page++;
                          _load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    required this.updating,
    required this.onStatusChanged,
  });

  final AdminBooking booking;
  final bool updating;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.bookingNumber,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                updating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value != booking.status) onStatusChanged(value);
                        },
                        itemBuilder: (context) => _statuses
                            .map(
                              (status) => PopupMenuItem(
                                value: status,
                                child: Text(formatStatus(status)),
                              ),
                            )
                            .toList(),
                        child: StatusBadge(status: booking.status),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            Text(booking.serviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              booking.customerName ?? booking.customerPhone ?? booking.customerEmail ?? '—',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${dateTimeFormat.format(booking.scheduledAt)} · ${currencyFormat.format(booking.totalAmount)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (booking.addressSummary != null) ...[
              const SizedBox(height: 4),
              Text(
                booking.addressSummary!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
