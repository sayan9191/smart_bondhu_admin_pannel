import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/app_error_mapper.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/core/utils/formatters.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';
import 'package:smartbandhu_admin/widgets/maintenance_view.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.api});

  final AdminApi api;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<AdminCatalogCategory> _categories = [];
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
      final categories = await widget.api.getCatalog();
      if (!mounted) return;
      setState(() {
        _categories = categories;
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

  String _slugify(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final imageController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category name'),
                onChanged: (v) {
                  if (slugController.text.isEmpty) slugController.text = _slugify(v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: slugController,
                decoration: const InputDecoration(labelText: 'Slug'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await widget.api.createCategory(
        name: nameController.text.trim(),
        slug: slugController.text.trim(),
        imageUrl: imageController.text.trim(),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _addSubCategory(AdminCatalogCategory category) async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add sub-category · ${category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Sub-category name'),
              onChanged: (v) {
                if (slugController.text.isEmpty) slugController.text = _slugify(v);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: slugController,
              decoration: const InputDecoration(labelText: 'Slug'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await widget.api.createSubCategory(
        categoryId: category.id,
        name: nameController.text.trim(),
        slug: slugController.text.trim(),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _addService(AdminCatalogCategory category, AdminCatalogSubCategory sub) async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final imageController = TextEditingController();
    final priceController = TextEditingController(text: '299');
    final durationController = TextEditingController(text: '60');
    final descController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add service · ${sub.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Service name'),
                onChanged: (v) {
                  if (slugController.text.isEmpty) slugController.text = _slugify(v);
                },
              ),
              const SizedBox(height: 10),
              TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug')),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (INR)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await widget.api.createService(
        subCategoryId: sub.id,
        name: nameController.text.trim(),
        slug: slugController.text.trim(),
        basePrice: double.parse(priceController.text.trim()),
        durationMinutes: int.parse(durationController.text.trim()),
        description: descController.text.trim(),
        imageUrl: imageController.text.trim(),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _editCategory(AdminCatalogCategory category) async {
    final saved = await _ContentEditor.show(
      context,
      title: 'Edit ${category.name}',
      name: category.name,
      description: category.description ?? '',
      imageUrl: category.iconUrl ?? category.imageUrl ?? '',
      coverUrl: category.imageUrl ?? '',
      active: category.isActive,
    );
    if (saved == null || !mounted) return;
    try {
      await widget.api.updateCategory(
        category.id,
        name: saved.name,
        description: saved.description,
        iconUrl: saved.imageUrl,
        imageUrl: saved.coverUrl,
        isActive: saved.active,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _editSubCategory(AdminCatalogSubCategory sub) async {
    final saved = await _ContentEditor.show(
      context,
      title: 'Edit sub-category',
      name: sub.name,
      description: sub.description ?? '',
      imageUrl: sub.iconUrl ?? '',
      active: sub.isActive,
    );
    if (saved == null || !mounted) return;
    try {
      await widget.api.updateSubCategory(
        sub.id,
        name: saved.name,
        description: saved.description,
        imageUrl: saved.imageUrl,
        isActive: saved.active,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _editService(AdminCatalogService service) async {
    final saved = await _ContentEditor.show(
      context,
      title: 'Edit service',
      name: service.name,
      description: service.description ?? '',
      imageUrl: service.imageUrl ?? '',
      active: service.isActive,
      price: service.basePrice.toStringAsFixed(0),
      duration: service.durationMinutes.toString(),
    );
    if (saved == null || !mounted) return;
    try {
      await widget.api.updateService(
        service.id,
        name: saved.name,
        description: saved.description,
        imageUrl: saved.imageUrl,
        isActive: saved.active,
        basePrice: double.parse(saved.price!),
        durationMinutes: int.parse(saved.duration!),
      );
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

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pictures and text here are what customers see in the app.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add category'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_categories.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No categories yet. Tap “Add category” to create one.'),
              ),
            )
          else
            ..._categories.map((category) {
              final serviceCount =
                  category.subCategories.fold<int>(0, (sum, sub) => sum + sub.services.length);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: _Thumb(url: category.iconUrl ?? category.imageUrl),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${category.subCategories.length} groups · $serviceCount services',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: category.isActive
                      ? null
                      : const Chip(label: Text('Inactive', style: TextStyle(fontSize: 11))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _editCategory(category),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit category'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _addSubCategory(category),
                            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                            label: const Text('Add sub-category'),
                          ),
                        ],
                      ),
                    ),
                    if (category.subCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text('No sub-categories yet.'),
                      )
                    else
                      ...category.subCategories.map((sub) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${sub.services.length} services'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Edit sub-category',
                                        onPressed: () => _editSubCategory(sub),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        tooltip: 'Add service',
                                        onPressed: () => _addService(category, sub),
                                      ),
                                    ],
                                  ),
                                ),
                                if (sub.services.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Text('No services in this group.'),
                                  )
                                else
                                  ...sub.services.map(
                                    (service) => ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.home_repair_service_outlined, size: 20),
                                      title: Text(service.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: Text('${service.durationMinutes} min · ${service.slug}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currencyFormat.format(service.basePrice),
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            tooltip: 'Edit service',
                                            onPressed: () => _editService(service),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        color: AppColors.background,
        child: hasUrl
            ? Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined))
            : const Icon(Icons.image_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}

class _ContentDraft {
  const _ContentDraft({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.active,
    this.coverUrl,
    this.price,
    this.duration,
  });

  final String name;
  final String description;
  final String imageUrl;
  final bool active;
  final String? coverUrl;
  final String? price;
  final String? duration;
}

class _ContentEditor extends StatefulWidget {
  const _ContentEditor({
    required this.title,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.active,
    this.coverUrl,
    this.price,
    this.duration,
  });

  final String title;
  final String name;
  final String description;
  final String imageUrl;
  final bool active;
  final String? coverUrl;
  final String? price;
  final String? duration;

  static Future<_ContentDraft?> show(
    BuildContext context, {
    required String title,
    required String name,
    required String description,
    required String imageUrl,
    required bool active,
    String? coverUrl,
    String? price,
    String? duration,
  }) {
    return showDialog<_ContentDraft>(
      context: context,
      builder: (context) => _ContentEditor(
        title: title,
        name: name,
        description: description,
        imageUrl: imageUrl,
        active: active,
        coverUrl: coverUrl,
        price: price,
        duration: duration,
      ),
    );
  }

  @override
  State<_ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<_ContentEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _coverUrl;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _description = TextEditingController(text: widget.description);
    _imageUrl = TextEditingController(text: widget.imageUrl);
    _coverUrl = TextEditingController(text: widget.coverUrl ?? '');
    _price = TextEditingController(text: widget.price ?? '');
    _duration = TextEditingController(text: widget.duration ?? '');
    _active = widget.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _coverUrl.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    if (widget.price != null) {
      if (double.tryParse(_price.text.trim()) == null || int.tryParse(_duration.text.trim()) == null) {
        return;
      }
    }
    Navigator.pop(
      context,
      _ContentDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        coverUrl: widget.coverUrl == null ? null : _coverUrl.text.trim(),
        active: _active,
        price: widget.price == null ? null : _price.text.trim(),
        duration: widget.duration == null ? null : _duration.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _imageUrl,
              decoration: InputDecoration(
                labelText: widget.coverUrl == null ? 'Photo URL' : 'Home screen icon URL',
                helperText: widget.coverUrl == null
                    ? 'Shown on the service in the customer app'
                    : 'Small picture under All services',
              ),
            ),
            if (widget.coverUrl != null) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _coverUrl,
                decoration: const InputDecoration(
                  labelText: 'Cover photo URL',
                  helperText: 'Large picture when the customer opens this category',
                ),
              ),
            ],
            if (widget.price != null) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (INR)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible in the customer app'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
