#!/usr/bin/env bash
# ============================================================
#  MikroTik Manager — Production Release Build Script
#  يبني APK موقّعاً جاهزاً للتوزيع (split per ABI + obfuscation)
#  التوقيع: من متغيرات البيئة (CI) أو android/key.properties (محلي)
#  الاستخدام: ./scripts/build_release_apk.sh [--skip-analyze]
# ============================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

SKIP_ANALYZE=false
[ "${1:-}" = "--skip-analyze" ] && SKIP_ANALYZE=true

# --- فحوصات ما قبل البناء ---
command -v flutter >/dev/null 2>&1 || { echo "❌ Flutter غير مثبت"; exit 1; }
[ -f android/app/release-keystore.jks ] || [ -n "${ANDROID_KEYSTORE_PATH:-}" ] \
  || { echo "❌ لا يوجد keystore — أنشئه وفق SIGNING.md"; exit 1; }

echo "▶ Flutter version: $(flutter --version 2>/dev/null | head -1)"

# --- 1) الاعتماديات ---
echo "▶ flutter pub get ..."
flutter pub get

# --- 2) تحليل الكود ---
if [ "$SKIP_ANALYZE" = false ]; then
  echo "▶ flutter analyze ..."
  flutter analyze || { echo "⚠️ يوجد ملاحظات تحليل — راجعها أو استخدم --skip-analyze"; exit 1; }
fi

# --- 3) بناء الإصدار ---
echo "▶ flutter build apk --release (split-per-abi + obfuscate) ..."
flutter build apk --release \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/app/symbols \
  --dart-define=FLUTTER_WEB=false

# --- 4) ملخص النتائج ---
echo ""
echo "✅ اكتمل البناء — الملفات الناتجة:"
ls -lh build/app/outputs/flutter-apk/*.apk 2>/dev/null | awk '{print "   " $9 "  (" $5 ")"}'
echo ""
echo "🔐 بيانات التوقيع:"
"${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}/build-tools"/*/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk 2>/dev/null | head -4 \
  || echo "   (apksigner غير متوفر — تحقق يدوياً: apksigner verify --print-certs <apk>)"
echo ""
echo "📦 رموز التشويش (احفظها لفك تشفير stack traces): build/app/symbols"
