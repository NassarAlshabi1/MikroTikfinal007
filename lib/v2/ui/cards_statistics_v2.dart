import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cards_stats_provider.dart';
import '../../perf/device_capability.dart';

/// شاشة إحصائيات الكروت — محسّنة للأجهزة الضعيفة
///
/// التحسينات:
/// 1) select() لكل حقل على حدة
/// 2) const على العناصر الثابتة (مفاتيح الإحصائيات)
/// 3) ListView.builder بدلاً من ListView مع ...map() (lazy build)
/// 4) RepaintBoundary حول البطاقات
class CardsStatisticsV2 extends ConsumerWidget {
  const CardsStatisticsV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ---- select() لكل حقل ----
    final loading = ref.watch(cardsStatsProvider.select((s) => s.loading));
    final users = ref.watch(cardsStatsProvider.select((s) => s.users));
    final sessions = ref.watch(cardsStatsProvider.select((s) => s.sessions));

    // نأخذ أول 10 فقط للعرض — نحسبها مرة واحدة
    final sampleUsers = users.take(10).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات الكروت V2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loading
                ? null
                : () => ref.read(cardsStatsProvider.notifier).refresh(),
          )
        ],
      ),
      body: loading && users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              scrollCacheExtent: ScrollCacheExtent.pixels(DeviceCapability.instance.listViewCacheExtent), padding: const EdgeInsets.all(12),
              // إجمالي العناصر: بطاقتان إحصائيتان + عنوان + عينة 10 مستخدمين
              itemCount: 2 + 1 + sampleUsers.length,
              addAutomaticKeepAlives: false,
              itemBuilder: (context, index) {
                // البطاقتان الأوليان
                if (index == 0) {
                  return RepaintBoundary(
                    child: Card(
                      child: ListTile(
                        title: const Text('عدد المستخدمين'),
                        trailing: Text('${users.length}'),
                      ),
                    ),
                  );
                }
                if (index == 1) {
                  return RepaintBoundary(
                    child: Card(
                      child: ListTile(
                        title: const Text('عدد الجلسات'),
                        trailing: Text('${sessions.length}'),
                      ),
                    ),
                  );
                }
                if (index == 2) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('عينة مستخدمين'),
                  );
                }
                // عينة المستخدمين
                final u = sampleUsers[index - 3];
                return ListTile(
                  title: Text('${u['username'] ?? '-'}'),
                  subtitle: Text('${u['actual-profile'] ?? '-'}'),
                  dense: DeviceCapability.instance.isLowEnd,
                );
              },
            ),
    );
  }
}
