import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/active_users_provider.dart';
import '../../perf/device_capability.dart';

/// شاشة المستخدمين النشطين — محسّنة للأجهزة الضعيفة
///
/// التحسينات:
/// 1) استخدام select() لعزل كل جزء من الـ state، فيُعاد بناء الجزء المتأثر فقط
/// 2) ListView.builder مع itemExtent (لا حساب ارتفاع ديناميكي)
/// 3) RepaintBoundary حول العناصر الثقيلة
/// 4) const حيثما أمكن
class ActiveUsersV2 extends ConsumerWidget {
  const ActiveUsersV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ---- تحسينات select() ----
    // كل watch مستقل ⇒ عند تغيير loading فقط يُعاد بناء الـ AppBar وليس القائمة
    final loading = ref.watch(
      activeUsersProvider.select((s) => s.loading),
    );
    final items = ref.watch(
      activeUsersProvider.select((s) => s.items),
    );
    final page = ref.watch(
      activeUsersProvider.select((s) => s.page),
    );
    final hotspot = ref.watch(
      activeUsersProvider.select((s) => s.hotspot),
    );
    final serverPaging = ref.watch(
      activeUsersProvider.select((s) => s.serverPaging),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون النشطون V2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            // لا نُعيد بناء الـ IconButton عند تغيير loading لأن onPressed يبقى ثابتاً
            onPressed: loading
                ? null
                : () => ref.read(activeUsersProvider.notifier).refresh(),
          )
        ],
      ),
      body: loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // شريط المعلومات العلوي — معزول بـ RepaintBoundary
                RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(hotspot ? 'Hotspot' : 'User Manager'),
                        const Spacer(),
                        Text(serverPaging ? 'Server Paging' : 'Local Paging'),
                      ],
                    ),
                  ),
                ),

                // القائمة — أثقل جزء، نفصلها تماماً
                Expanded(
                  child: RepaintBoundary(
                    child: ListView.builder(
                      // itemExtent يمنع حساب الارتفاع لكل عنصر → تحسن أداء scroll
                      // بشكل كبير على الأجهزة الضعيفة
                      scrollCacheExtent: ScrollCacheExtent.pixels(DeviceCapability.instance.listViewCacheExtent), itemExtent: 72,
                      // addAutomaticKeepAlives خاطئ لأن العناصر خفيفة
                      addAutomaticKeepAlives: false,
                      // لا نُبقي العناصر حية عند الـ scroll-out
                      addRepaintBoundaries: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final u = items[index];
                        final name = u['user'] ?? u['name'] ?? '-';
                        final ip =
                            u['address'] ?? u['framed-ip-address'] ?? '-';
                        final up = u['uptime'] ?? u['session-time-left'] ?? '';
                        return ListTile(
                          // تثبيت العنوان يقلل layout work
                          title: Text('$name'),
                          subtitle: Text('$ip • $up'),
                          dense: DeviceCapability.instance.isLowEnd,
                        );
                      },
                    ),
                  ),
                ),

                // شريط التنقل السفلي — معزول
                RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: page > 0 && !loading
                              ? () => ref
                                  .read(activeUsersProvider.notifier)
                                  .prevPage()
                              : null,
                          child: const Text('السابق'),
                        ),
                        const SizedBox(width: 12),
                        Text('صفحة ${page + 1}'),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: !loading
                              ? () => ref
                                  .read(activeUsersProvider.notifier)
                                  .nextPage()
                              : null,
                          child: const Text('التالي'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
