import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/config/app_config.dart';
import 'package:smartbandhu_admin/core/network/api_client.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/shell/admin_shell_page.dart';
import 'package:smartbandhu_admin/widgets/admin_splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initSync();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  Future<void>? _bootFuture;
  int _bootAttempt = 0;

  @override
  void initState() {
    super.initState();
    _bootFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AppConfig.init().timeout(const Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      key: ValueKey(_bootAttempt),
      future: _bootFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
          final api = AdminApi(ApiClient());
          if (kDebugMode) {
            debugPrint('SmartBondhu Admin API → ${AppConfig.apiBaseUrl}');
          }
          return SmartBondhuAdminApp(api: api);
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Could not connect to the backend.\nRun: ./scripts/run_dev.sh setup',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _bootAttempt++;
                            _bootFuture = _bootstrap();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return const AdminSplashView();
      },
    );
  }
}

class SmartBondhuAdminApp extends StatelessWidget {
  const SmartBondhuAdminApp({super.key, required this.api});

  final AdminApi api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AdminShellPage(api: api),
    );
  }
}
