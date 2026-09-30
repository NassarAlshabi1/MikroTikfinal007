import 'package:flutter/material.dart';

import '../database/isar_provider.dart';

/// Process-wide services shared by legacy screens during the gradual migration.
///
/// IsarProvider is itself a singleton, so keeping one stable reference also
/// makes app bootstrap safe when integration tests invoke [main] repeatedly.
final IsarProvider appDatabaseProvider = IsarProvider();

/// Global messenger used by services that cannot access a BuildContext.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
