import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/app_error_mapper.dart';
import 'package:smartbandhu_admin/core/config/app_config.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';

String _bannerImageUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final api = AppConfig.apiBaseUrl;
  const suffix = '/api/v1';
  final origin = api.endsWith(suffix) ? api.substring(0, api.length - suffix.length) : api;
  final path = url.startsWith('/') ? url : '/$url';
  return '$origin$path';
}

class BannersPage extends StatefulWidget {
  const BannersPage({super.key, required this.api});

  final AdminApi api;

  @override
  State<BannersPage> createState() => _BannersPageState();
}

class _BannersPageState extends State<BannersPage> {
  List<AdminBanner> _banners = [];
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
      final banners = await widget.api.getBanners();
      if (!mounted) return;
      setState(() {
        _banners = banners;
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

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _BannerFormDialog(api: widget.api),
    );
    if (created == true) _load();
  }

  Future<void> _edit(AdminBanner banner) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _BannerFormDialog(api: widget.api, existing: banner),
    );
    if (saved == true) _load();
  }

  Future<void> _toggle(AdminBanner banner, bool active) async {
    try {
      await widget.api.updateBanner(banner.id, isActive: active);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _delete(AdminBanner banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete banner'),
        content: Text('Remove “${banner.title}” from the home screen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteBanner(banner.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Add banner'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      const Text(
                        'These images show in the carousel on the customer home screen. Paste an image URL, or upload one to storage and paste the returned link.',
                        style: TextStyle(color: AppColors.textSecondary, height: 1.35),
                      ),
                      const SizedBox(height: 16),
                      if (_banners.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text('No banners yet. The app shows the three built-in promos until you add one.'),
                        ),
                      for (final banner in _banners)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 2.4,
                                      child: Image.network(
                                      _bannerImageUrl(banner.imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const ColoredBox(
                                        color: Color(0xFFE7F6EF),
                                        child: Center(child: Icon(Icons.image_not_supported_outlined)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(banner.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  'Order ${banner.sortOrder} · ${banner.action}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                Row(
                                  children: [
                                    const Text('Visible'),
                                    Switch(
                                      value: banner.isActive,
                                      onChanged: (value) => _toggle(banner, value),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => _edit(banner),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      onPressed: () => _delete(banner),
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _BannerFormDialog extends StatefulWidget {
  const _BannerFormDialog({required this.api, this.existing});

  final AdminApi api;
  final AdminBanner? existing;

  @override
  State<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<_BannerFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _imageUrl;
  late final TextEditingController _sort;
  late String _action;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    _sort = TextEditingController(text: '${existing?.sortOrder ?? 0}');
    _action = existing?.action ?? 'services';
  }

  @override
  void dispose() {
    _title.dispose();
    _imageUrl.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _imageUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and image URL are required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final title = _title.text.trim();
      final imageUrl = _imageUrl.text.trim();
      final sortOrder = int.tryParse(_sort.text.trim()) ?? 0;
      final existing = widget.existing;
      if (existing == null) {
        await widget.api.createBanner(
          title: title,
          imageUrl: imageUrl,
          sortOrder: sortOrder,
          action: _action,
        );
      } else {
        await widget.api.updateBanner(
          existing.id,
          title: title,
          imageUrl: imageUrl,
          sortOrder: sortOrder,
          action: _action,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add banner' : 'Edit banner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _imageUrl,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            TextField(
              controller: _sort,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sort order'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _action,
              decoration: const InputDecoration(labelText: 'Tap action'),
              items: const [
                DropdownMenuItem(value: 'services', child: Text('Open services')),
                DropdownMenuItem(value: 'offers', child: Text('Open offers')),
                DropdownMenuItem(value: 'none', child: Text('No action')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _action = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save')),
      ],
    );
  }
}
