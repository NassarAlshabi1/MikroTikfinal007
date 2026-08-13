import 'dart:async';
import 'dart:io';

import 'connection_service.dart';
import 'mikrotik_connector.dart';

enum MikrotikCardSource { userManager, hotspot }

extension MikrotikCardSourceLabel on MikrotikCardSource {
  String get label => switch (this) {
        MikrotikCardSource.userManager => 'مدير المستخدمين',
        MikrotikCardSource.hotspot => 'Hotspot',
      };

  String get command => switch (this) {
        MikrotikCardSource.userManager => '/tool/user-manager/user/print',
        MikrotikCardSource.hotspot => '/ip/hotspot/user/print',
      };
}

class MikrotikCard {
  MikrotikCard({
    required this.id,
    required this.username,
    required this.profile,
    required this.isDisabled,
    required this.comment,
    required this.source,
  });

  final String id;
  final String username;
  final String profile;
  final bool isDisabled;
  final String comment;
  final MikrotikCardSource source;

  String get statusLabel => isDisabled ? 'معطّل' : 'نشط';

  /// فهرس بحث يُبنى مرة واحدة لكل كرت، لتجنب تحويل الحقول إلى أحرف صغيرة
  /// مع كل ضغطة على مربع البحث.
  late final String normalizedSearchText =
      '$username $profile $comment'.toLowerCase();

  factory MikrotikCard.fromRouterResponse(
    Map<String, dynamic> item,
    MikrotikCardSource source,
  ) {
    final isHotspot = source == MikrotikCardSource.hotspot;
    final username = isHotspot ? item['name'] : item['username'];
    final profile = isHotspot ? item['profile'] : item['actual-profile'];

    return MikrotikCard(
      id: item['.id']?.toString() ?? '',
      username: username?.toString().trim() ?? '',
      profile: (profile?.toString().trim().isEmpty ?? true)
          ? 'غير محدد'
          : profile.toString().trim(),
      isDisabled: item['disabled']?.toString().toLowerCase() == 'true',
      comment: item['comment']?.toString().trim() ?? '',
      source: source,
    );
  }
}

class MikrotikCardSyncResult {
  const MikrotikCardSyncResult({
    required this.cards,
    required this.syncedAt,
    required this.elapsed,
    required this.fromCache,
  });

  final List<MikrotikCard> cards;
  final DateTime syncedAt;
  final Duration elapsed;
  final bool fromCache;
}

class MikrotikCardOperationException implements Exception {
  const MikrotikCardOperationException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// طبقة موحدة وسريعة لتحميل كروت MikroTik والبحث فيها خلال جلسة التطبيق.
/// لا تحفظ هذه الطبقة كلمات المرور أو النسخة الكاملة من الكروت على القرص.
class MikrotikCardRepository {
  MikrotikCardRepository._();

  static final MikrotikCardRepository instance = MikrotikCardRepository._();

  final Map<MikrotikCardSource, _CardCache> _cache = {};
  final Map<MikrotikCardSource, Future<MikrotikCardSyncResult>> _pendingSyncs =
      {};

  static const Duration _cacheLifetime = Duration(minutes: 2);

  Future<MikrotikCardSyncResult> sync({
    required MikrotikCardSource source,
    bool forceRefresh = false,
  }) {
    final cached = _cache[source];
    final isCacheFresh = cached != null &&
        DateTime.now().difference(cached.syncedAt) < _cacheLifetime;
    if (!forceRefresh && isCacheFresh) {
      return Future.value(
        MikrotikCardSyncResult(
          cards: List.unmodifiable(cached.cards),
          syncedAt: cached.syncedAt,
          elapsed: Duration.zero,
          fromCache: true,
        ),
      );
    }

    final activeRequest = _pendingSyncs[source];
    if (activeRequest != null) return activeRequest;

    final request = _syncFromRouter(source);
    _pendingSyncs[source] = request;
    return request.whenComplete(() => _pendingSyncs.remove(source));
  }

  List<MikrotikCard> searchLocal({
    required MikrotikCardSource source,
    required String query,
  }) {
    final cards = _cache[source]?.cards ?? const <MikrotikCard>[];
    return filterCards(cards: cards, query: query);
  }

  /// فلترة محلية متزامنة لا تعتمد على الشبكة، ويمكن اختبار أدائها مباشرة.
  static List<MikrotikCard> filterCards({
    required Iterable<MikrotikCard> cards,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return List.unmodifiable(cards);

    return cards
        .where((card) => card.normalizedSearchText.contains(normalizedQuery))
        .toList(growable: false);
  }

  void clearCache([MikrotikCardSource? source]) {
    if (source == null) {
      _cache.clear();
      return;
    }
    _cache.remove(source);
  }

  Future<MikrotikCardSyncResult> _syncFromRouter(
    MikrotikCardSource source,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final client = await ConnectionService.instance.getClient();
      final response = await client.talk([
        source.command,
        if (source == MikrotikCardSource.userManager)
          '=.proplist=.id,username,disabled,actual-profile,comment,shared-users,uptime-limit,uptime-used'
        else
          '=.proplist=.id,name,disabled,profile,comment,limit-uptime,uptime,bytes-in,bytes-out',
      ]).timeout(const Duration(seconds: 20));
      ConnectionService.instance.keepAlive();

      final cards = response
          .whereType<Map>()
          .map((item) => MikrotikCard.fromRouterResponse(
                Map<String, dynamic>.from(item),
                source,
              ))
          .where((card) => card.username.isNotEmpty)
          .toList(growable: false)
        ..sort((left, right) => left.username.compareTo(right.username));

      final now = DateTime.now();
      _cache[source] = _CardCache(cards: cards, syncedAt: now);
      return MikrotikCardSyncResult(
        cards: List.unmodifiable(cards),
        syncedAt: now,
        elapsed: stopwatch.elapsed,
        fromCache: false,
      );
    } on MikrotikCredentialsMissingException catch (error) {
      throw MikrotikCardOperationException(
        'بيانات الاتصال غير مكتملة. افتح إعدادات الاتصال وأدخل بيانات الراوتر أولاً.',
        error,
      );
    } on MikrotikConnectionException catch (error) {
      throw MikrotikCardOperationException(error.message, error);
    } on TimeoutException catch (error) {
      throw MikrotikCardOperationException(
        'استغرقت المزامنة وقتاً أطول من المتوقع. تحقق من الشبكة وحاول مجدداً.',
        error,
      );
    } on SocketException catch (error) {
      throw MikrotikCardOperationException(
        'تعذر الوصول إلى الراوتر. تأكد من العنوان والمنفذ واتصال الهاتف بالشبكة.',
        error,
      );
    } catch (error) {
      throw MikrotikCardOperationException(
        'تعذر جلب الكروت من ${source.label}. تأكد من أن المستخدم يملك صلاحية القراءة وأن الخدمة مفعلة في الراوتر.',
        error,
      );
    } finally {
      stopwatch.stop();
    }
  }
}

class _CardCache {
  const _CardCache({required this.cards, required this.syncedAt});

  final List<MikrotikCard> cards;
  final DateTime syncedAt;
}
