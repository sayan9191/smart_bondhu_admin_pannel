import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/app_error_mapper.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';

class MaintenanceView extends StatelessWidget {
  const MaintenanceView({super.key, this.onRetry, this.message});

  final VoidCallback? onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home_repair_service_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              AppErrorMapper.maintenanceTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? AppErrorMapper.maintenanceMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
