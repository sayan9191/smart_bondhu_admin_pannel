import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/app_error_mapper.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/data/models/admin_models.dart';
import 'package:smartbandhu_admin/widgets/maintenance_view.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key, required this.api});

  final AdminApi api;

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  AppSettings? _settings;
  bool _loading = true;
  bool _saving = false;
  bool _sending = false;
  String? _error;

  final _maintenanceMessageController = TextEditingController();
  final _minAndroidController = TextEditingController();
  final _minIosController = TextEditingController();
  final _notifTitleController = TextEditingController(text: 'New offer available');
  final _notifBodyController = TextEditingController(
    text: 'Tap to view the latest offers on Smart Bondhu.',
  );
  final _notifCodeController = TextEditingController(text: 'WELCOME50');
  String _notifScreen = 'offers';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _maintenanceMessageController.dispose();
    _minAndroidController.dispose();
    _minIosController.dispose();
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    _notifCodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await widget.api.getAppSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _maintenanceMessageController.text = settings.maintenanceMessage;
        _minAndroidController.text = settings.minAndroidVersion;
        _minIosController.text = settings.minIosVersion;
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

  Future<void> _saveSettings() async {
    final current = _settings;
    if (current == null) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.api.updateAppSettings(
        AppSettings(
          maintenanceMode: current.maintenanceMode,
          maintenanceMessage: _maintenanceMessageController.text.trim(),
          forceUpdate: current.forceUpdate,
          minAndroidVersion: _minAndroidController.text.trim(),
          minIosVersion: _minIosController.text.trim(),
          androidStoreUrl: current.androidStoreUrl,
          iosStoreUrl: current.iosStoreUrl,
        ),
      );
      if (!mounted) return;
      setState(() => _settings = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App settings saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendNotification() async {
    setState(() => _sending = true);
    try {
      final result = await widget.api.broadcastNotification(
        title: _notifTitleController.text.trim(),
        body: _notifBodyController.text.trim(),
        screen: _notifScreen,
        code: _notifCodeController.text.trim().isEmpty ? null : _notifCodeController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent to ${result.recipients} users')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null || _settings == null) {
      return MaintenanceView(message: _error, onRetry: _load);
    }

    final settings = _settings!;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'App control',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Maintenance, force update & push alerts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Maintenance mode',
            icon: Icons.home_repair_service_outlined,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Under maintenance'),
                subtitle: const Text('Customer app shows maintenance bottom sheet'),
                value: settings.maintenanceMode,
                onChanged: _saving
                    ? null
                    : (value) => setState(
                          () => _settings = AppSettings(
                            maintenanceMode: value,
                            maintenanceMessage: settings.maintenanceMessage,
                            forceUpdate: settings.forceUpdate,
                            minAndroidVersion: settings.minAndroidVersion,
                            minIosVersion: settings.minIosVersion,
                            androidStoreUrl: settings.androidStoreUrl,
                            iosStoreUrl: settings.iosStoreUrl,
                          ),
                        ),
              ),
              TextField(
                controller: _maintenanceMessageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Maintenance message',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Force update',
            icon: Icons.system_update_alt_outlined,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require app update'),
                subtitle: const Text('Blocks customer app until they update'),
                value: settings.forceUpdate,
                onChanged: _saving
                    ? null
                    : (value) => setState(
                          () => _settings = AppSettings(
                            maintenanceMode: settings.maintenanceMode,
                            maintenanceMessage: settings.maintenanceMessage,
                            forceUpdate: value,
                            minAndroidVersion: settings.minAndroidVersion,
                            minIosVersion: settings.minIosVersion,
                            androidStoreUrl: settings.androidStoreUrl,
                            iosStoreUrl: settings.iosStoreUrl,
                          ),
                        ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minAndroidController,
                      decoration: const InputDecoration(
                        labelText: 'Min Android version',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _minIosController,
                      decoration: const InputDecoration(
                        labelText: 'Min iOS version',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveSettings,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save app settings'),
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Send notification',
            icon: Icons.notifications_active_outlined,
            children: [
              TextField(
                controller: _notifTitleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notifBodyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notifCodeController,
                decoration: const InputDecoration(
                  labelText: 'Offer code (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _notifScreen,
                decoration: const InputDecoration(
                  labelText: 'Open screen on tap',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'offers', child: Text('Offers tab')),
                  DropdownMenuItem(value: 'bookings', child: Text('Bookings tab')),
                ],
                onChanged: _sending ? null : (v) => setState(() => _notifScreen = v ?? 'offers'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _sendNotification,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Sending…' : 'Send to all users'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
