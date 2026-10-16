# بنية MikroNet

تطبيق Flutter + GetX لإدارة أجهزة MikroTik (بطاقات، مستخدمون، هوتسبوت، طباعة، مبيعات، موزعون، صيانة، بوت تيليجرام)، واجهة عربية RTL بثيم داكن.

## البنية العامة (Feature-first)

```
lib/
├── app/                    # نقطة الدخول وإعدادات التطبيق العامة
│   ├── app.dart            # GetMaterialApp + الثيم + الترجمة
│   ├── routes/
│   │   ├── app_routes.dart # ثوابت أسماء المسارات
│   │   ├── app_pages.dart  # تجميع مسارات كل الميزات
│   │   └── pages/          # ملف مسارات لكل ميزة (XRoutes.routes)
│   └── theme/              # app_theme.dart + app_colors.dart (مصدر الألوان الوحيد)
│
├── core/                   # طبقة مشتركة مستقلة عن الميزات
│   ├── mikrotik/           # عميل RouterOS (router_os_client + mikrotik_client + mikrotik_base)
│   ├── storage/            # SQLite (db_api) + التخزين المشفر (secure_storage)
│   ├── network/            # فحص الشبكة (scanner, ping, tracert, mac_diagnostics)
│   ├── models/             # نماذج مشتركة بين الميزات
│   ├── services/           # خدمات عامة (backup_service, session)
│   ├── ui/                 # widgets وdialogs مشتركة
│   └── utils/              # أدوات مساعدة (helpers, mikrotik_config, app_logger)
│
└── features/<feature>/     # كل ميزة في مجلد مستقل
    ├── data/               # APIs وجلب البيانات
    ├── controllers/        # GetX controllers + bindings
    └── views/              # الشاشات والودجات الخاصة بالميزة

الميزات: auth, home, cards, users, hotspot, prints, reports,
         distributors, maintenance, sites, backup, telegram
```

## القواعد

- **المسارات**: `AppPages.pages` يجمّع `XRoutes.routes` من `app/routes/pages/`؛ لإضافة شاشة ضع مسارها في ملف الميزة لا في ملف موحّد.
- **الحقن**: تستخدم `Bindings` داخل `GetPage` (بعضها مع `Get.arguments`) — لا `Get.put` داخل `build` أو `initState`.
- **الألوان**: كل الألوان عبر `AppColors` فقط؛ `AppTheme` يبني `ThemeData` عليها. لا `Color(0x...)` في شاشات الميزات.
- **RouterOS**: عميل واحد فقط (`core/mikrotik/`) — ممنوع تكرار الموقتات/مُعالجة السوكت خارجها.
- **الاختبارات**: `flutter test` يشغّل المجموعة كاملة (CI يفعل نفس الشيء).
- **CI**: `flutter analyze --no-fatal-infos --no-fatal-warnings` يجب أن يمرّ بنتيجة صفر مشاكل.
