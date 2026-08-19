import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router_service.dart';
import 'optimized_providers.dart';

/// State مُحسّن: const constructor
class CardsStatsState {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> sessions;
  final bool loading;
  final String? error;

  const CardsStatsState({
    required this.users,
    required this.sessions,
    required this.loading,
    required this.error,
  });

  CardsStatsState copyWith({
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? sessions,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      CardsStatsState(
        users: users ?? this.users,
        sessions: sessions ?? this.sessions,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );

  static CardsStatsState initial() => const CardsStatsState(
        users: [],
        sessions: [],
        loading: false,
        error: null,
      );
}

/// Notifier محسّن:
/// - caching في الذاكرة لكل من users و sessions
/// - async متوازي (Future.wait) لتقليل زمن الانتظار
/// - لا loading flicker عند وجود cache
class CardsStatsNotifier extends StateNotifier<CardsStatsState> {
  CardsStatsNotifier(this._ref, {this.maxRecords = 50, this.chunk = 20})
      : super(CardsStatsState.initial());

  final Ref _ref;
  final int maxRecords;
  final int chunk;
  final _service = RouterService();

  static const _usersKey = 'cards_stats_users';
  static const _sessionsKey = 'cards_stats_sessions';

  Future<void> fetch() async {
    final cache = _ref.read(responseCacheProvider);

    // تحقق من الـ cache أولاً
    final cachedUsers = cache.get(_usersKey);
    final cachedSessions = cache.get(_sessionsKey);
    if (cachedUsers != null && cachedSessions != null) {
      state = state.copyWith(
        users: cachedUsers,
        sessions: cachedSessions,
        clearError: true,
      );
      // fetch في الخلفية لإعادة التحديث (silently)
      _refreshInBackground();
      return;
    }

    final showLoading = state.users.isEmpty && state.sessions.isEmpty;
    if (showLoading) {
      state = state.copyWith(loading: true, clearError: true);
    }

    try {
      // Future.wait لتشغيل الطلبات بالتوازي (نصف الزمن تقريباً)
      final results = await Future.wait([
        _fetchPaginated(
          '/ip/hotspot/user/print',
          'name,password,disabled,profile,limit-uptime,limit-bytes-total',
        ),
        _fetchPaginated(
          '/ip/hotspot/active/print',
          'user,bytes-in,bytes-out,uptime,session-time-left',
        ),
      ]);

      final users = _normalizeHotspotUsers(results[0]);
      final sessions = _normalizeHotspotSessions(results[1]);

      cache.put(_usersKey, users);
      cache.put(_sessionsKey, sessions);

      state = state.copyWith(
        users: users,
        sessions: sessions,
        loading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }

  /// تحديث صامت في الخلفية — لا يُحدث loading state
  Future<void> _refreshInBackground() async {
    try {
      final results = await Future.wait([
        _fetchPaginated(
          '/ip/hotspot/user/print',
          'name,password,disabled,profile,limit-uptime,limit-bytes-total',
        ),
        _fetchPaginated(
          '/ip/hotspot/active/print',
          'user,bytes-in,bytes-out,uptime,session-time-left',
        ),
      ]);
      final cache = _ref.read(responseCacheProvider);
      final users = _normalizeHotspotUsers(results[0]);
      final sessions = _normalizeHotspotSessions(results[1]);
      cache.put(_usersKey, users);
      cache.put(_sessionsKey, sessions);
      // حدّث الـ state مرة واحدة فقط (وليس في كل خطوة)
      if (mounted) {
        state = state.copyWith(
          users: users,
          sessions: sessions,
          clearError: true,
        );
      }
    } catch (_) {
      // تجاهل الأخطاء في التحديث الخلفي
    }
  }

  List<Map<String, dynamic>> _normalizeHotspotUsers(
      List<Map<String, dynamic>> users) {
    return users
        .map((user) => {
              ...user,
              'username': user['name'] ?? user['username'],
              'actual-profile': user['profile'] ?? user['actual-profile'],
              'uptime-limit': user['limit-uptime'] ?? user['uptime-limit'],
            })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _normalizeHotspotSessions(
      List<Map<String, dynamic>> sessions) {
    return sessions
        .map((session) => {
              ...session,
              'upload': session['bytes-in'] ?? session['upload'],
              'download': session['bytes-out'] ?? session['download'],
            })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchPaginated(
      String path, String proplist) async {
    final all = <Map<String, dynamic>>[];
    int skip = 0;
    while (all.length < maxRecords) {
      try {
        final res = await _service.talkPaged(
            path: path, proplist: proplist, limit: chunk, skip: skip);
        all.addAll(res);
        if (res.length < chunk) break;
        skip += chunk;
      } catch (_) {
        final res = await _service.talk([path, '=.proplist=$proplist']);
        all.addAll(res);
        break;
      }
    }
    if (all.length > maxRecords) {
      return all.sublist(0, maxRecords);
    }
    return all;
  }

  /// مسح cache عند الـ pull-to-refresh
  void refresh() {
    final cache = _ref.read(responseCacheProvider);
    cache.invalidate(_usersKey);
    cache.invalidate(_sessionsKey);
    fetch();
  }
}

final cardsStatsProvider =
    StateNotifierProvider<CardsStatsNotifier, CardsStatsState>(
  (ref) => CardsStatsNotifier(ref, maxRecords: 50, chunk: 20),
);
