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
                      'Catalog',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_categories.length} categories',
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
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${category.subCategories.length} sub-categories · $serviceCount services',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: category.isActive
                      ? null
                      : const Chip(label: Text('Inactive', style: TextStyle(fontSize: 11))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _addSubCategory(category),
                          icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                          label: const Text('Add sub-category'),
                        ),
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
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    tooltip: 'Add service',
                                    onPressed: () => _addService(category, sub),
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
                                      trailing: Text(
                                        currencyFormat.format(service.basePrice),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
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
