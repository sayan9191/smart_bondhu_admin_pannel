import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/core/utils/formatters.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';
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
  bool _loading = true;
  String? _error;
  String? _updatingId;

  @override
  void initState() {
    super.initState();
    _load();
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
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(AdminBooking booking, String status) async {
    setState(() => _updatingId = booking.id);
    try {
      await widget.api.updateBookingStatus(booking.id, status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
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
              Text(
                'Bookings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
                  ),
                  const SizedBox(width: 8),
                  DropdownMenu<String>(
                    initialSelection: _statusFilter,
                    label: const Text('Status'),
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(value: '', label: 'All'),
                      ..._statuses.map(
                        (s) => DropdownMenuEntry(value: s, label: formatStatus(s)),
                      ),
                    ],
                    onSelected: (value) {
                      _page = 1;
                      _statusFilter = value ?? '';
                      _load();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: AppColors.error)),
          ),
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
                StatusBadge(status: booking.status),
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
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey('${booking.id}-${booking.status}'),
              initialValue: booking.status,
              decoration: const InputDecoration(
                labelText: 'Update status',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: _statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(formatStatus(s))))
                  .toList(),
              onChanged: updating ? null : (value) {
                if (value != null && value != booking.status) {
                  onStatusChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
