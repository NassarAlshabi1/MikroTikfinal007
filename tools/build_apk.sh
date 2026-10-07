#!/usr/bin/env bash
#
# بناء APK محليًا مع **رفع رقم الإصدار تلقائيًا** — نفس منطق CI بالضبط:
#   versionName = 2.0.0.<N>   ·   versionCode = 2000 + <N>
#   حيث N = (أعلى رقم بناء منشور في GitHub Releases) + 1
#
# الاستخدام:
#   ./tools/build_apk.sh            # يرفع الرقم تلقائيًا
#   ./tools/build_apk.sh 2.0.0.60   # يفرض رقمًا محددًا
#
# ملاحظة: قراءة الإصدارات المنشورة تحتاج `gh` مع صلاحية الوصول للمستودع.
#         إن تعذّر ذلك، استخدم الرقم الصريح أو سيبدأ العدّ من 1.

set -euo pipefail

REPO_SLUG="${MIKRONET_REPO:-NassarAlshabi1/MikroTikfinal007}"
BASE_CODE=2000
VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  PREV="$(gh api "repos/$REPO_SLUG/releases?per_page=100" -q '.[].tag_name' 2>/dev/null \
          | grep -oE '\-b[0-9]+$' | tr -d 'b-' | sort -n | tail -1 || true)"
  N=$(( ${PREV:-0} + 1 ))
  if [ "$N" -le 0 ]; then N=1; fi
  VERSION="2.0.0.$N"
  echo "آخر إصدار منشور: ${PREV:-لا شيء} ⇒ الإصدار الجديد: $VERSION"
else
  N="${VERSION##*.}"
  case "$N" in
    ''|*[!0-9]*) N=0 ;;
  esac
  echo "إصدار محدَّد يدويًا: $VERSION"
fi

CODE=$(( BASE_CODE + N ))

echo "versionName=$VERSION  versionCode=$CODE"
flutter build apk --release --target-platform android-arm64 \
  --build-name="$VERSION" --build-number="$CODE"

APK="build/app/outputs/flutter-apk/app-release.apk"
echo
echo "✅ تم البناء: $APK"
echo "   ملف النشر (واحد فقط): MikroNet-2.0.0.0-arm64.apk  (رقم الإصدار: $VERSION)"
echo
if [ -f android/signing.properties ]; then
  echo "🔐 التوقيع: مفتاح MikroNet الثابت ⇒ التثبيت فوق أي نسخة سابقة يعمل بلا تعارض."
else
  echo "⚠️  تحذير: android/signing.properties غير موجود — سيُوقَّع الإصدار بمفتاح التصحيح"
  echo "    ولن يُثبَّت فوق النسخ المنشورة (ستظهر رسالة تعارض الحزمة)."
fi
