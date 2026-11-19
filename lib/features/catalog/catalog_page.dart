import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Ids of categories the user has expanded. Collapsed categories render only
  // their header row (no hidden sub-tree), which keeps layout simple and safe.
  final Set<String> _expanded = <String>{};

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

  // Refresh the data WITHOUT blanking the screen to a spinner (used after
  // add / edit / delete and on pull-to-refresh).
  Future<void> _refresh() async {
    try {
      final categories = await widget.api.getCatalog();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      // Ignore a transient refresh failure (e.g. a serverless cold start):
      // the data already on screen stays and the next action refreshes it.
    }
  }

  String _slugify(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirmDelete(String what, {String? extra}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete $what?'),
            content: Text(extra ?? 'This cannot be undone.'),
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
  }

  // ---------------- Category ----------------
  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final imageController = TextEditingController();
    bool uploading = false;
    String? uploadError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
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
                TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug')),
                const SizedBox(height: 14),
                _imageField(imageController, uploading, uploadError, setLocal, (u) => uploading = u, (e) => uploadError = e),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: uploading ? null : () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await widget.api.createCategory(
        name: nameController.text.trim(),
        slug: slugController.text.trim(),
        imageUrl: imageController.text.trim(),
      );
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  Future<void> _editCategory(AdminCatalogCategory category) async {
    final nameController = TextEditingController(text: category.name);
    final imageController = TextEditingController();
    bool uploading = false;
    String? uploadError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Edit category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category name')),
                const SizedBox(height: 14),
                _imageField(imageController, uploading, uploadError, setLocal, (u) => uploading = u, (e) => uploadError = e),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Upload a new photo to replace the current image.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: uploading ? null : () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await widget.api.updateCategory(
        category.id,
        name: nameController.text.trim(),
        imageUrl: imageController.text.trim(),
      );
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  Future<void> _deleteCategory(AdminCatalogCategory category) async {
    final ok = await _confirmDelete('category "${category.name}"',
        extra: 'This also deletes its sub-categories and services. This cannot be undone.');
    if (!ok || !mounted) return;
    try {
      await widget.api.deleteCategory(category.id);
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  // ---------------- Sub-category ----------------
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
            TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug')),
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
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  Future<void> _editSubCategory(AdminCatalogSubCategory sub) async {
    final nameController = TextEditingController(text: sub.name);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit sub-category'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Sub-category name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    try {
      await widget.api.updateSubCategory(sub.id, name: nameController.text.trim());
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  Future<void> _deleteSubCategory(AdminCatalogSubCategory sub) async {
    final ok = await _confirmDelete('sub-category "${sub.name}"',
        extra: 'This also deletes its services. This cannot be undone.');
    if (!ok || !mounted) return;
    try {
      await widget.api.deleteSubCategory(sub.id);
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  // ---------------- Service ----------------
  Future<void> _addService(AdminCatalogCategory category, AdminCatalogSubCategory sub) async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final priceController = TextEditingController(text: '299');
    final durationController = TextEditingController(text: '60');
    final descController = TextEditingController();
    final imageController = TextEditingController();
    bool uploading = false;
    String? uploadError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
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
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (INR)')),
                const SizedBox(height: 10),
                TextField(controller: durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (minutes)')),
                const SizedBox(height: 10),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 2),
                const SizedBox(height: 14),
                _imageField(imageController, uploading, uploadError, setLocal, (u) => uploading = u, (e) => uploadError = e),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: uploading ? null : () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await widget.api.createService(
        subCategoryId: sub.id,
        name: nameController.text.trim(),
        slug: slugController.text.trim(),
        basePrice: double.tryParse(priceController.text.trim()) ?? 0,
        durationMinutes: int.tryParse(durationController.text.trim()) ?? 60,
        description: descController.text.trim(),
        imageUrl: imageController.text.trim(),
      );
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  Future<void> _editService(AdminCatalogService service) async {
    final nameController = TextEditingController(text: service.name);
    final priceController = TextEditingController(text: service.basePrice.toStringAsFixed(0));
    final durationController = TextEditingController(text: service.durationMinutes.toString());
    final imageController = TextEditingController();
    bool uploading = false;
    String? uploadError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Edit service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Service name')),
                const SizedBox(height: 10),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (INR)')),
                const SizedBox(height: 10),
                TextField(controller: durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (minutes)')),
                const SizedBox(height: 14),
                _imageField(imageController, uploading, uploadError, setLocal, (u) => uploading = u, (e) => uploadError = e),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: uploading ? null : () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await widget.api.updateService(
        service.id,
        name: nameController.text.trim(),
        basePrice: double.tryParse(priceController.text.trim()),
        durationMinutes: int.tryParse(durationController.text.trim()),
        imageUrl: imageController.text.trim(),
      );
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  Future<void> _deleteService(AdminCatalogService service) async {
    final ok = await _confirmDelete('service "${service.name}"');
    if (!ok || !mounted) return;
    try {
      await widget.api.deleteService(service.id);
      await _refresh();
    } catch (e) {
      _toast(AppErrorMapper.message(e));
    }
  }

  Widget _imageField(
    TextEditingController controller,
    bool uploading,
    String? uploadError,
    void Function(void Function()) setLocal,
    void Function(bool) setUploading,
    void Function(String?) setError,
  ) {
    return _ImagePickerField(
      api: widget.api,
      imageController: controller,
      uploading: uploading,
      uploadError: uploadError,
      onStart: () => setLocal(() {
        setUploading(true);
        setError(null);
      }),
      onDone: (url) => setLocal(() {
        controller.text = url;
        setUploading(false);
      }),
      onError: (msg) => setLocal(() {
        setUploading(false);
        setError(msg);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return MaintenanceView(message: _error, onRetry: _load);
    }

    final itemCount = _categories.isEmpty ? 2 : _categories.length + 1;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) return _header(context);
          if (_categories.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No categories yet. Tap "Add category" to create one.'),
              ),
            );
          }
          return _categoryCard(_categories[index - 1]);
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Catalog', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text('${_categories.length} categories',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          FilledButton.icon(onPressed: _addCategory, icon: const Icon(Icons.add, size: 18), label: const Text('Add category')),
        ],
      ),
    );
  }

  Widget _categoryCard(AdminCatalogCategory category) {
    final serviceCount = category.subCategories.fold<int>(0, (sum, sub) => sum + sub.services.length);
    final isOpen = _expanded.contains(category.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () => setState(() {
              if (isOpen) {
                _expanded.remove(category.id);
              } else {
                _expanded.add(category.id);
              }
            }),
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${category.subCategories.length} sub-categories · $serviceCount services',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary),
                PopupMenuButton<String>(
                  tooltip: 'Category options',
                  onSelected: (v) {
                    if (v == 'edit') {
                      _editCategory(category);
                    } else if (v == 'delete') {
                      _deleteCategory(category);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit category')),
                    PopupMenuItem(value: 'delete', child: Text('Delete category')),
                  ],
                ),
              ],
            ),
          ),
          if (isOpen) _categoryBody(category),
        ],
      ),
    );
  }

  Widget _categoryBody(AdminCatalogCategory category) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          for (final sub in category.subCategories) _subCategoryTile(category, sub),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _subCategoryTile(AdminCatalogCategory category, AdminCatalogSubCategory sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${sub.services.length} services'),
              trailing: PopupMenuButton<String>(
                tooltip: 'Sub-category options',
                onSelected: (v) {
                  if (v == 'add') {
                    _addService(category, sub);
                  } else if (v == 'edit') {
                    _editSubCategory(sub);
                  } else if (v == 'delete') {
                    _deleteSubCategory(sub);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'add', child: Text('Add service')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
            if (sub.services.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('No services in this group.'),
              )
            else
              for (final service in sub.services) _serviceTile(service),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _serviceTile(AdminCatalogService service) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.home_repair_service_outlined, size: 20),
      title: Text(service.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${service.durationMinutes} min · ${currencyFormat.format(service.basePrice)}'),
      trailing: PopupMenuButton<String>(
        tooltip: 'Service options',
        onSelected: (v) {
          if (v == 'edit') {
            _editService(service);
          } else if (v == 'delete') {
            _deleteService(service);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

/// Image field used in the dialogs: pick a photo from the gallery, upload it
/// (the backend compresses it), and keep the resulting public URL.
class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.api,
    required this.imageController,
    required this.uploading,
    required this.uploadError,
    required this.onStart,
    required this.onDone,
    required this.onError,
  });

  final AdminApi api;
  final TextEditingController imageController;
  final bool uploading;
  final String? uploadError;
  final VoidCallback onStart;
  final void Function(String url) onDone;
  final void Function(String message) onError;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000);
    if (picked == null) return;
    onStart();
    try {
      final url = await api.uploadCatalogImage(picked.path);
      onDone(url);
    } catch (e) {
      onError(AppErrorMapper.message(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageController.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Image', style: TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        if (hasImage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageController.text,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 120, width: 120, child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: uploading ? null : _pick,
          icon: uploading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.photo_library_outlined, size: 18),
          label: Text(uploading ? 'Uploading...' : (hasImage ? 'Change image' : 'Choose from gallery')),
        ),
        if (uploadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(uploadError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: imageController,
          decoration: const InputDecoration(labelText: 'Image URL (auto-filled, or paste one)', isDense: true),
        ),
      ],
    );
  }
}
