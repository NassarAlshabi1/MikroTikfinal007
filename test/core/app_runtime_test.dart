import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/core/app_runtime.dart' as runtime;
import 'package:mikrotik_manager/database/isar_provider.dart';
import 'package:mikrotik_manager/main.dart' as legacy_entrypoint;

void main() {
  group('application runtime compatibility', () {
    test('the entrypoint re-exports the stable shared services', () {
      expect(
        legacy_entrypoint.appDatabaseProvider,
        same(runtime.appDatabaseProvider),
      );
      expect(
        legacy_entrypoint.scaffoldMessengerKey,
        same(runtime.scaffoldMessengerKey),
      );
    });

    test('database provider remains a process-wide singleton', () {
      expect(runtime.appDatabaseProvider, same(IsarProvider()));
    });
  });
}
