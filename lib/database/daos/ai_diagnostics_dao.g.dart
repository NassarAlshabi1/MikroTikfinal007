// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_diagnostics_dao.dart';

// ignore_for_file: type=lint
mixin _$AiDiagnosticsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AiDiagnosticsTable get aiDiagnostics => attachedDatabase.aiDiagnostics;
  $ExecutedCommandsTable get executedCommands =>
      attachedDatabase.executedCommands;
  AiDiagnosticsDaoManager get managers => AiDiagnosticsDaoManager(this);
}

class AiDiagnosticsDaoManager {
  final _$AiDiagnosticsDaoMixin _db;
  AiDiagnosticsDaoManager(this._db);
  $$AiDiagnosticsTableTableManager get aiDiagnostics =>
      $$AiDiagnosticsTableTableManager(_db.attachedDatabase, _db.aiDiagnostics);
  $$ExecutedCommandsTableTableManager get executedCommands =>
      $$ExecutedCommandsTableTableManager(
          _db.attachedDatabase, _db.executedCommands);
}
