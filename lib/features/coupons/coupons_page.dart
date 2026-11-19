import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartbandhu_admin/core/app_error_mapper.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/widgets/maintenance_view.dart';

/// Admin screen to manage discount coupons. These are stored on the backend
/// and shown in the customer app's Offers screen, so changing them here needs
/// no app rebuild.
class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key, required this.api});

  final AdminApi api;

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _Coupon {
  _Coupon(Map<String, dynamic> j)
      : id = (j['id'] ?? '').toString(),
        code = (j['code'] ?? '').toString(),
        type = (j['coupon_type'] ?? 'fixed').toString(),
        value = _d(j['value']),
        minOrder = j['min_order_amount'] == null ? null : _d(j['min_order_amount']),
        isActive = (j['is_active'] as bool?) ?? true,
        description = j['description'] as String?;

  final String id;
  final String code;
  final String type;
  final double value;
  final double? minOrder;
  final bool isActive;
  final String? description;

  bool get isPercent => type.toLowerCase().startsWith('percent') || type == '%';

  static double _d(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;
}

class _CouponsPageState extends State<CouponsPage> {
  List<_Coupon> _coupons = [];
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
      final rows = await widget.api.getCoupons();
      if (!mounted) return;
      setState(() {
        _coupons = rows.map((e) => _Coupon(e)).toList();
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

  // Refresh without blanking the screen; ignore transient failures.
  Future<void> _refresh() async {
    try {
      final rows = await widget.api.getCoupons();
      if (!mounted) return;
      setState(() => _coupons = rows.map((e) => _Coupon(e)).toList());
    } catch (_) {
      // Keep the data already on screen (e.g. on a cold start).
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _editDialog({_Coupon? existing}) async {
    final codeController = TextEditingController(text: existing?.code ?? '');
    final valueController =
        TextEditingController(text: existing != null ? existing.value.toStringAsFixed(0) : '');
    final minController = TextEditingController(
        text: existing?.minOrder != null ? existing!.minOrder!.toStringAsFixed(0) : '');
    String type = existing != null && existing.isPercent ? 'percentage' : 'fixed';
    bool active = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add coupon' : 'Edit coupon'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Coupon code (e.g. SAVE50)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Discount type'),
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Flat Rs off')),
                    DropdownMenuItem(value: 'percentage', child: Text('Percentage %')),
                  ],
                  onChanged: (v) => setLocal(() => type = v ?? 'fixed'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: type == 'percentage' ? 'Discount percent' : 'Discount amount (Rs)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minimum order amount (Rs)'),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active (shown in app)'),
                  value: active,
                  onChanged: (v) => setLocal(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final code = codeController.text.trim().toUpperCase();
    final value = double.tryParse(valueController.text.trim()) ?? 0;
    final minOrder = minController.text.trim().isEmpty ? null : double.tryParse(minController.text.trim());
    if (code.isEmpty || value <= 0) {
      _toast('Enter a code and a discount value');
      return;
    }
    try {
      if (existing == null) {
        await widget.api.createCoupon(
          code: code,
          couponType: type,
          value: value,
          minOrderAmount: minOrder,
          isActive: active,
        );
      } else {
        await widget.api.updateCoupon(
          existing.id,
          code: code,
          couponType: type,
          value: value,
          minOrderAmount: minOrder,
          isActive: active,
        );
      }
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  Future<void> _delete(_Coupon c) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete ${c.code}?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    try {
      await widget.api.deleteCoupon(c.id);
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  Future<void> _toggleActive(_Coupon c) async {
    try {
      await widget.api.updateCoupon(c.id, isActive: !c.isActive);
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
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

    final itemCount = _coupons.isEmpty ? 2 : _coupons.length + 1;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coupons',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          '${_coupons.length} coupons - shown in the customer app',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _editDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            );
          }
          if (_coupons.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No coupons yet. Tap "Add" to create one.'),
              ),
            );
          }
          return _couponCard(_coupons[index - 1]);
        },
      ),
    );
  }

  Widget _couponCard(_Coupon c) {
    final discount = c.isPercent ? '${c.value.toStringAsFixed(0)}% off' : 'Flat Rs ${c.value.toStringAsFixed(0)} off';
    final min = c.minOrder == null ? 'No minimum' : 'Min order Rs ${c.minOrder!.toStringAsFixed(0)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(Icons.local_offer, color: c.isActive ? AppColors.primary : AppColors.textSecondary),
        title: Row(
          children: [
            Flexible(
              child: Text(c.code,
                  style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            if (!c.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Inactive', style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
        subtitle: Text('$discount - $min', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          tooltip: 'Coupon options',
          onSelected: (v) {
            if (v == 'edit') {
              _editDialog(existing: c);
            } else if (v == 'copy') {
              Clipboard.setData(ClipboardData(text: c.code));
              _toast('${c.code} copied');
            } else if (v == 'toggle') {
              _toggleActive(c);
            } else if (v == 'delete') {
              _delete(c);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'copy', child: Text('Copy code')),
            PopupMenuItem(value: 'toggle', child: Text(c.isActive ? 'Deactivate' : 'Activate')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
