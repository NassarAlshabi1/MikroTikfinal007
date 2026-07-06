import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router_service.dart';
import 'optimized_providers.dart';

/// State يستخدم قيم final و const لتقليل الـ allocations
class ActiveUsersState {
  final List<Map<String, dynamic>> items;
  final bool loading;
  final String? error;
  final bool hotspot;
  final bool serverPaging;
  final int page;
  final int pageSize;

  const ActiveUsersState({
    required this.items,
    required this.loading,
    required this.error,
    required this.hotspot,
    required this.serverPaging,
    required this.page,
    required this.pageSize,
  });

  /// نسخة محسّنة: فقط الحقول المتغيّرة تُنشأ من جديد
  ActiveUsersState copyWith({
    List<Map<String, dynamic>>? items,
    bool? loading,
    String? error,
    bool? hotspot,
    bool? serverPaging,
    int? page,
    int? pageSize,
    // لتمييز "null" عن "عدم التغيير" في error
    bool clearError = false,
  }) =>
      ActiveUsersState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        hotspot: hotspot ?? this.hotspot,
        serverPaging: serverPaging ?? this.serverPaging,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );

  static ActiveUsersState initial(int pageSize) => ActiveUsersState(
        items: const [],
        loading: false,
        error: null,
        hotspot: true,
        serverPaging: false,
        page: 0,
        pageSize: pageSize,
      );
}

/// Notifier محسّن:
/// 1) يأخذ ref للوصول إلى cache
/// 2) يستخدم cache لتجنّب إعادة الجلب عند العودة لصفحة سابقة
/// 3) لا يُحدث state عند الفشل (يمنع إعادة بناء الواجهة بلا داعي)
class ActiveUsersNotifier extends StateNotifier<ActiveUsersState> {
  ActiveUsersNotifier(this._ref, {this.pageSize = 20})
      : super(ActiveUsersState.initial(pageSize));

  final Ref _ref;
  final int pageSize;
  final _service = RouterService();

  String _cacheKey(int p) => 'active_users_p$p';

  Future<void> fetch({int? page}) async {
    final targetPage = page ?? state.page;
    final cache = _ref.read(responseCacheProvider);
    final cached = cache.get(_cacheKey(targetPage));
    if (cached != null) {
      // استخدم cache ⇒ لا loading state ⇒ لا flicker
      state = state.copyWith(
        items: cached,
        page: targetPage,
        clearError: true,
      );
      return;
    }

    // اعرض loading فقط إذا كانت القائمة فارغة (تجنّب flicker)
    final showLoading = state.items.isEmpty;
    if (showLoading) {
      state = state.copyWith(loading: true, page: targetPage, clearError: true);
    }

    try {
      // محاولة سريعة: paging على مستوى الخادم
      try {
        final res = await _service.talkPaged(
          path: '/ip/hotspot/active/print',
          proplist: 'user,address,uptime',
          limit: pageSize,
          skip: targetPage * pageSize,
        );
        cache.put(_cacheKey(targetPage), res);
        state = state.copyWith(
          items: res,
          hotspot: true,
          serverPaging: true,
          loading: false,
          page: targetPage,
          clearError: true,
        );
        return;
      } catch (_) {}

      // محاولة ثانية: hotspot بدون paging
      final resHot = await _service
          .talk(['/ip/hotspot/active/print', '=.proplist=user,address,uptime']);
      cache.put(_cacheKey(targetPage), resHot);
      state = state.copyWith(
        items: resHot,
        hotspot: true,
        serverPaging: false,
        loading: false,
        page: targetPage,
        clearError: true,
      );
    } catch (_) {
      // محاولة أخيرة: user-manager
      try {
        final res = await _service.talkPaged(
          path: '/tool/user-manager/session/print',
          proplist: 'user,session-time-left,framed-ip-address,uptime',
          limit: pageSize,
          skip: targetPage * pageSize,
        );
        cache.put(_cacheKey(targetPage), res);
        state = state.copyWith(
          items: res,
          hotspot: false,
          serverPaging: true,
          loading: false,
          page: targetPage,
          clearError: true,
        );
      } catch (_) {
        try {
          final res = await _service.talk([
            '/tool/user-manager/session/print',
            '=.proplist=user,session-time-left,framed-ip-address,uptime'
          ]);
          cache.put(_cacheKey(targetPage), res);
          state = state.copyWith(
            items: res,
            hotspot: false,
            serverPaging: false,
            loading: false,
            page: targetPage,
            clearError: true,
          );
        } catch (e) {
          state = state.copyWith(
            loading: false,
            error: e.toString(),
            page: targetPage,
          );
        }
      }
    }
  }

  void nextPage() {
    final p = state.page + 1;
    state = state.copyWith(page: p);
    fetch(page: p);
  }

  void prevPage() {
    if (state.page == 0) return;
    final p = state.page - 1;
    state = state.copyWith(page: p);
    fetch(page: p);
  }

  /// مسح الـ cache عند الـ pull-to-refresh
  void refresh() {
    final cache = _ref.read(responseCacheProvider);
    cache.invalidate(_cacheKey(state.page));
    fetch();
  }
}

final activeUsersProvider =
    StateNotifierProvider<ActiveUsersNotifier, ActiveUsersState>(
  (ref) => ActiveUsersNotifier(ref, pageSize: 20),
);
