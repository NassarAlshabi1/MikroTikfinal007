import 'package:flutter/material.dart';
import 'theme/app_palette.dart';

void showErrorSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.onSurface, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
      backgroundColor: AppPalette.error,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'إغلاق',
        textColor: Theme.of(context).colorScheme.onSurface,
        onPressed: () {},
      ),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.onSurface, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
      backgroundColor: AppPalette.success,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}
