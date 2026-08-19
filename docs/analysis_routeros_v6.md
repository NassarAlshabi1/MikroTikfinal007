# تحليل توافق RouterOS v6 وإنشاء Hotspot cards

## مراجع رسمية

- MikroTik RouterOS API: https://help.mikrotik.com/docs/spaces/ROS/pages/47579160/API
- MikroTik HotSpot: https://help.mikrotik.com/docs/spaces/ROS/pages/56459266/HotSpot+-+Captive+portal

## نتائج أولية

توضح وثائق MikroTik أن API يعتمد على أوامر تحاكي مسارات CLI، وأن كل طلب يتكون من command word ثم attribute words وينتهي بجملة API. كما تؤكد الوثائق أن خدمة API العادية تستخدم TCP 8728 والآمنة TCP 8729 افتراضياً.

صفحة HotSpot الرسمية تفصل بين HotSpot Users ومسارات User Manager؛ لذلك فإن إنشاء كروت Hotspot محلية يجب أن يستخدم `/ip/hotspot/user/add` مع حقول المستخدم والبروفايل الخاصة بـ HotSpot، وليس `/tool/user-manager/user/add` أو `create-and-activate-profile` إلا إذا كان التطبيق يدير User Manager/RADIUS عمداً.

## ملاحظات من الكود

- `HomeScreen` يعرّف `MikrotikMode.hotspot` لكنه يثبت `_selectedMode` على `MikrotikMode.userManager`، لذلك يجلب `/tool/user-manager/profile/print` دائماً.
- `BulkAddScreen` لا يملك نمط خدمة مستقل؛ يأخذ قائمة profiles القادمة من `HomeScreen`.
- `bulk_add_isolate.dart` ينفذ `/tool/user-manager/user/add` ثم `/tool/user-manager/user/create-and-activate-profile`، وبالتالي لا ينشئ Hotspot users محليين.
- `add_user_screen.dart` يكرر نفس مسارات User Manager.
- `database/sync_service.dart` يزامن `/tool/user-manager/profile/print` و`/tool/user-manager/user/print` ويعتمد على `actual-profile`، وهو غير مناسب كمسار Hotspot محلي.
- اختبارات `bulk_add_isolate_test.dart` و`cards_creation_test.dart` لا تختبر أوامر RouterOS الحقيقية ولا تميز بين Hotspot وUser Manager.

## فجوات عالية الأولوية

1. فصل نمط الخدمة إلى `hotspot` و`userManager` بدلاً من hard-code.
2. إنشاء خدمة أوامر واحدة لـ Hotspot v6 تُستخدم في الإنشاء الفردي والجماعي والمزامنة.
3. استخدام `/ip/hotspot/user/add` و`=profile=<profile>` و`=shared-users=<n>` مع عدم إرسال `customer` في مسار Hotspot.
4. منع إنشاء كلمة مرور فارغة عند نمط username-only إلا بعد التحقق من سلوك الراوتر؛ الافتراضي الأكثر أماناً لكروت Hotspot هو جعل password=username أو توليد password واضح للمستخدم.
5. إصلاح `Random()` داخل كل حرف في مولد الكروت، وإضافة ضمان uniqueness داخل الدفعة.
6. إضافة اختبارات command-building باستخدام fake client أو abstraction بدلاً من اختبار مولد البيانات فقط.
7. عدم اعتبار نجاح `talk()` وحده نجاحاً نهائياً دون فحص `!trap`/رسائل الخطأ التي قد ترجعها مكتبة العميل.
