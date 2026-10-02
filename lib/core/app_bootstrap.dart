import 'package:flutter/widgets.dart';

import '../database/migration_service.dart';
import '../services/app_logger.dart';
import '../services/secure_credentials_storage.dart';
import 'app_runtime.dart';

/// Initializes durable services before the first frame is rendered.
///
/// Migration failures are deliberately non-fatal: the app can still open, the
/// failure is recorded, and the migration service can retry on a later launch.
Future<void> bootstrapApplication() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await appDatabaseProvider.instance;
    AppLogger.info(
      'Isar database opened successfully',
      category: LogCategory.system,
    );

    await SecureCredentialsStorageContainer.instance
        .migrateFromSharedPreferences();
    await MigrationService.instance.migrateLegacyDataIfNeeded();
  } catch (error, stackTrace) {
    AppLogger.error(
      'Application bootstrap migration failed',
      error: error,
      stackTrace: stackTrace,
      category: LogCategory.system,
    );
  }

  AppLogger.info('App starting', category: LogCategory.system);
}
