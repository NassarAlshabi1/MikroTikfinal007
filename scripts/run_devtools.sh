#!/bin/bash
# ============================================================
#  سكربت تشغيل Flutter DevTools بوضع --profile
#
#  الاستخدام:
#    ./scripts/run_devtools.sh
#
#  المتطلبات:
#    - Flutter SDK مثبّت
#    - جهاز فعلي متصل (Android/iOS) أو محاكي
#    - CMake (لـ Linux desktop) أو Android Studio (لمحاكي Android)
# ============================================================

set -e

echo "🚀 تشغيل Flutter DevTools بوضع --profile"
echo "============================================================"
echo ""

# التحقق من Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter غير مثبّت. ثبّته من https://flutter.dev"
    exit 1
fi

# التحقق من الأجهزة المتاحة
echo "📱 الأجهزة المتاحة:"
flutter devices
echo ""

# تشغيل DevTools في الخلفية
echo "🔧 تشغيل Flutter DevTools..."
flutter pub global activate devtools 2>/dev/null || true

# تشغيل التطبيق بوضع --profile
echo ""
echo "🏃 تشغيل التطبيق بوضع --profile..."
echo "   سيفتح DevTools تلقائياً في المتصفح"
echo ""
echo "📊 ما تراقبه:"
echo "   - Performance: Frame rate, jank, build time"
echo "   - Memory: Heap usage, leaks, GC pressure"
echo "   - CPU Profiler: Hot functions"
echo "   - Flutter Inspector: Highlight rebuilds"
echo ""
echo "⏹️  اضغط Ctrl+C لإيقاف التطبيق"
echo "============================================================"

# تشغيل التطبيق مع DevTools
flutter run --profile --trace-startup --devtools

# ملاحظة: --trace-startup يسجّل زمن بدء التشغيل
# --devtools يفتح DevTools تلقائياً
