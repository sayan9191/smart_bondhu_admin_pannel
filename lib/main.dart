import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/config/app_config.dart';
import 'package:smartbandhu_admin/core/network/api_client.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/shell/admin_shell_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(SmartBondhuAdminApp(api: AdminApi(ApiClient())));
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
