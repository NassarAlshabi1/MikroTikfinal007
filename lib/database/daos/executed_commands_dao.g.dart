// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'executed_commands_dao.dart';

// ignore_for_file: type=lint
mixin _$ExecutedCommandsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AiDiagnosticsTable get aiDiagnostics => attachedDatabase.aiDiagnostics;
  $ExecutedCommandsTable get executedCommands =>
      attachedDatabase.executedCommands;
  ExecutedCommandsDaoManager get managers => ExecutedCommandsDaoManager(this);
}

class ExecutedCommandsDaoManager {
  final _$ExecutedCommandsDaoMixin _db;
  ExecutedCommandsDaoManager(this._db);
  $$AiDiagnosticsTableTableManager get aiDiagnostics =>
      $$AiDiagnosticsTableTableManager(_db.attachedDatabase, _db.aiDiagnostics);
  $$ExecutedCommandsTableTableManager get executedCommands =>
      $$ExecutedCommandsTableTableManager(
          _db.attachedDatabase, _db.executedCommands);
}
