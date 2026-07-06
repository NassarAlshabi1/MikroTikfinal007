// ============================================================
//  دليل Riverpod select() — أنماط موصى بها للأداء
// ============================================================
//
//  المشكلة:
//  عندما تكتب `ref.watch(provider)` بدون select، فإن أي تغيير
//  في أي حقل من الـ state يُعيد بناء الـ Widget بالكامل.
//  على شاشة فيها قائمة بـ 100 عنصر، هذا يعني إعادة بناء الـ ListView
//  وكل ListTile كل مرة يتغيّر فيها `loading` مثلاً!
//
//  الحل:
//  استخدم select() لعزل الجزء الذي يهمّ الـ Widget الحالي فقط.

// ❌ خطأ — يُعاد بناء كل شيء عند أي تغيير
// ref.watch(activeUsersProvider)

// ✅ صحيح — كل watch مستقل، فيُعاد بناء الجزء المتأثر فقط
// final loading  = ref.watch(activeUsersProvider.select((s) => s.loading));
// final items    = ref.watch(activeUsersProvider.select((s) => s.items));
// final page     = ref.watch(activeUsersProvider.select((s) => s.page));

// ============================================================
//  أمثلة عملية لأنماط شائعة
// ============================================================

/*
// النمط 1: قائمة + حالة loading منفصلة
class MyScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(myProvider.select((s) => s.loading));
    final items   = ref.watch(myProvider.select((s) => s.items));

    return Scaffold(
      appBar: AppBar(
        // الـ AppBar يُعاد بناؤه فقط عند تغيّر loading
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loading ? null : () => ref.read(myProvider.notifier).fetch(),
          ),
        ],
      ),
      // الـ ListView يُعاد بناؤه فقط عند تغيّر items
      body: ListView.builder(
        itemCount: items.length,
        itemExtent: 72,  // مهم: يُسرّع الـ scroll
        itemBuilder: (c, i) => ListTile(title: Text(items[i]['name'])),
      ),
    );
  }
}
*/

/*
// النمط 2: استخدام select مع == على القيمة المُرجعة
// Riverpod يستخدم == لتحديد إذا كان سيُعيد البناء
// لذا فإن اختيار bool/int/String يكون مثالياً لأنها have built-in ==
//
// للقوائم: List ===== identity-based
//   - لذا أي تغيير في القائمة (حتى إضافة عنصر) يُشغّل البناء
//   - هذا هو السلوك المطلوب عادةً
//
// لكن: إذا كانت القائمة لا تتغيّر لكن حقول أخرى تتغيّر،
// فإن select يمنع إعادة بناء الـ ListView — وهذا هو الهدف.
*/

/*
// النمط 3: عزل قطعة صغيرة من البيانات
// بدلاً من:
//   final user = ref.watch(userProvider);  // كل المستخدم
// نكتب:
//   final name = ref.watch(userProvider.select((u) => u.name));
//   final avatar = ref.watch(userProvider.select((u) => u.avatarUrl));
//
// إذا تغيّر حقل الـ email مثلاً، فلن يُعاد بناء الـ widget
// الذي يعرض الـ name فقط.
*/

/*
// النمط 4: select مع family
// final item = ref.watch(itemProvider(id).select((s) => s.title));
*/

/*
// النمط 5: تجنّب watch داخل itemBuilder
// ❌ خطأ:
//   itemBuilder: (c, i) {
//     final item = ref.watch(itemProvider(ids[i]));  // إعادة بناء!
//     return ListTile(title: Text(item.title));
//   }
//
// ✅ صحيح: استخدم Consumer أو ConsumerWidget للعنصر نفسه
//   itemBuilder: (c, i) => ItemTile(id: ids[i])
//
// class ItemTile extends ConsumerWidget {
//   final String id;
//   const ItemTile({required this.id});
//   Widget build(BuildContext context, WidgetRef ref) {
//     final title = ref.watch(itemProvider(id).select((s) => s.title));
//     return ListTile(title: Text(title));
//   }
// }
*/

// ============================================================
//  قواعد ذهبية
// ============================================================
//
// 1) استخدم select() دائماً عند الـ watch، إلا إذا كنت فعلاً تحتاج الـ state كاملاً
// 2) افصل الـ watches: كل حقل في watch مستقل ⇒ عزل إعادة البناء
// 3) لا تستخدم watch داخل itemBuilder — استخدم ConsumerWidget منفصل
// 4) استخدم ref.read للـ actions (onPressed, onTap) — لا تُشغّل إعادة بناء
// 5) استخدم ref.listen لـ side-effects (snackbar, navigation) — لا يُعيد البناء
// 6) للقوائم: itemExtent + RepaintBoundary حول كل عنصر ثقيل
// 7) للـ cache: ضع cacheExtent منخفضاً على الأجهزة الضعيفة
