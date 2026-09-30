import '../database/isar_provider.dart';

/// Process-wide infrastructure dependencies initialized during bootstrap.
///
/// Keeping infrastructure ownership outside the widget tree prevents feature
/// screens from importing the application entry point. This remains a small
/// compatibility seam until all services are injected through providers.
late final IsarProvider appDatabaseProvider;

Future<void> initializeAppDependencies() async {
  appDatabaseProvider = IsarProvider();
  await appDatabaseProvider.instance;
}
