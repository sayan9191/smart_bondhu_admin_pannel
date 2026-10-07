import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartbandhu_admin/core/app_error_mapper.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';
import 'package:smartbandhu_admin/widgets/maintenance_view.dart';

class EnquiriesPage extends StatefulWidget {
  const EnquiriesPage({super.key, required this.api});

  final AdminApi api;

  @override
  State<EnquiriesPage> createState() => _EnquiriesPageState();
}

class _EnquiriesPageState extends State<EnquiriesPage> {
  static const _statuses = ['new', 'in_review', 'contacted', 'quoted', 'closed'];

  List<WebsiteEnquiry> _items = [];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final items = await widget.api.getEnquiries();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  List<WebsiteEnquiry> get _visible {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) {
      final text = '${item.name} ${item.phone} ${item.enquiryCode} ${item.service} ${item.requirement}'
          .toLowerCase();
      return text.contains(query);
    }).toList();
  }

  Future<void> _setStatus(WebsiteEnquiry item, String status) async {
    try {
      await widget.api.updateEnquiry(item.id, status: status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _editNote(WebsiteEnquiry item) async {
    final controller = TextEditingController(text: item.notes);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Internal note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Note'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    try {
      await widget.api.updateEnquiry(item.id, notes: controller.text.trim());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return MaintenanceView(message: _error, onRetry: _load);
    }

    final items = _visible;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Website enquiries',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Requests people send from the Smart Bondhu website',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search name, phone, or enquiry ID',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No website enquiries yet.'),
              ),
            )
          else
            ...items.map((item) {
              final when = item.createdAt == null
                  ? ''
                  : DateFormat('d MMM, h:mm a').format(item.createdAt!.toLocal());
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.name} · ${item.enquiryCode}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text('${item.phone} · ${item.service}', style: const TextStyle(color: AppColors.textSecondary)),
                      if (when.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(when, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                      const SizedBox(height: 10),
                      Text(item.requirement),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Note: ${item.notes}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _statuses.contains(item.status) ? item.status : 'new',
                              decoration: const InputDecoration(labelText: 'Status'),
                              items: _statuses
                                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null && value != item.status) _setStatus(item, value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _editNote(item),
                            child: const Text('Note'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
