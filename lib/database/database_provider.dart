// ============================================================
//  Database Providers — Riverpod providers للوصول لـ Isar
//
//  تمت الهجرة من Drift إلى Isar بالكامل.
//  المميزات:
//  - singleton عبر IsarProvider
//  - DAOs تُنشأ عند الحاجة فقط (lazy)
//  - Stream Providers للاستعلامات الـ reactive
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'isar_provider.dart';
import 'isar/card_collection.dart';
import 'isar/profile_collection.dart';
import 'isar/ai_diagnostic_collection.dart';
import 'isar/executed_command_collection.dart';
import 'daos/cards_dao.dart';
import 'daos/profiles_dao.dart';
import 'daos/ai_diagnostics_dao.dart';
import 'daos/executed_commands_dao.dart';

/// Singleton للـ Isar instance
final isarProvider = FutureProvider<IsarProvider>((ref) async {
  return IsarProvider();
});

/// Provider لـ Isar instance مباشرة
final isarInstanceProvider = FutureProvider((ref) async {
  final provider = await ref.watch(isarProvider.future);
  return provider.instance;
});

/// Provider لـ CardsDao
final cardsDaoProvider = FutureProvider<CardsDao>((ref) async {
  final isar = await ref.watch(isarInstanceProvider.future);
  return CardsDao(isar);
});

/// Provider لـ ProfilesDao
final profilesDaoProvider = FutureProvider<ProfilesDao>((ref) async {
  final isar = await ref.watch(isarInstanceProvider.future);
  return ProfilesDao(isar);
});

/// Provider لـ AiDiagnosticsDao
final aiDiagnosticsDaoProvider = FutureProvider<AiDiagnosticsDao>((ref) async {
  final isar = await ref.watch(isarInstanceProvider.future);
  return AiDiagnosticsDao(isar);
});

/// Provider لـ ExecutedCommandsDao
final executedCommandsDaoProvider =
    FutureProvider<ExecutedCommandsDao>((ref) async {
  final isar = await ref.watch(isarInstanceProvider.future);
  return ExecutedCommandsDao(isar);
});

// ============================================================
//  Stream Providers (reactive queries)
// ============================================================

/// Stream لكل الكروت
final watchAllCardsProvider =
    StreamProvider<List<CardCollection>>((ref) async* {
  final dao = await ref.watch(cardsDaoProvider.future);
  yield* dao.watchAllCards();
});

/// Stream للكروت النشطة
final watchActiveCardsProvider =
    StreamProvider<List<CardCollection>>((ref) async* {
  final dao = await ref.watch(cardsDaoProvider.future);
  yield* dao.watchActiveCards();
});

/// Stream للملفات الشخصية
final watchAllProfilesProvider =
    StreamProvider<List<ProfileCollection>>((ref) async* {
  final dao = await ref.watch(profilesDaoProvider.future);
  yield* dao.watchAllProfiles();
});

/// Stream لكل جلسات التشخيص
final watchAllDiagnosticsProvider =
    StreamProvider<List<AiDiagnosticCollection>>((ref) async* {
  final dao = await ref.watch(aiDiagnosticsDaoProvider.future);
  yield* dao.watchAllDiagnostics();
});

/// Stream للجلسات المفضلة
final watchFavoriteDiagnosticsProvider =
    StreamProvider<List<AiDiagnosticCollection>>((ref) async* {
  final dao = await ref.watch(aiDiagnosticsDaoProvider.future);
  yield* dao.watchFavoriteDiagnostics();
});

/// Stream للأوامر المنفّذة الأخيرة
final watchRecentCommandsProvider =
    StreamProvider<List<ExecutedCommandCollection>>((ref) async* {
  final dao = await ref.watch(executedCommandsDaoProvider.future);
  yield* dao.watchRecentCommands(50);
});

// ============================================================
//  Future Providers (one-time queries)
// ============================================================

/// إحصائيات الكروت
final cardsStatisticsProvider =
    FutureProvider<CardsStatistics>((ref) async {
  final dao = await ref.watch(cardsDaoProvider.future);
  return dao.getStatistics();
});

/// إحصائيات الأوامر المنفّذة
final commandsStatisticsProvider =
    FutureProvider<CommandsStatistics>((ref) async {
  final dao = await ref.watch(executedCommandsDaoProvider.future);
  return dao.getStatistics();
});

/// إحصائيات التشخيصات
final diagnosticsStatisticsProvider =
    FutureProvider<DiagnosticsStatistics>((ref) async {
  final dao = await ref.watch(aiDiagnosticsDaoProvider.future);
  return dao.getStatistics();
});

/// التقرير الشهري للأوامر
final monthlyCommandsReportProvider =
    FutureProvider<List<MonthlyCommandReport>>((ref) async {
  final dao = await ref.watch(executedCommandsDaoProvider.future);
  return dao.getMonthlyReport();
});
