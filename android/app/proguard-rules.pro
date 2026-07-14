# ============================================================
#  ProGuard / R8 Rules  —  MikroTik Manager
#  مُحسّن للأجهزة الضعيفة: تصغير الحجم + تسريع الإقلاع
# ============================================================

# ---------- Flutter Engine ----------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ---------- Google ML Kit (OCR + Document Scanner) ----------
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.mlkit.vision.docscanner.** { *; }
-keep class com.google.mlkit.common.** { *; }
-dontwarn com.google.mlkit.**

# ---------- Camera ----------
-keep class io.flutter.plugins.camera.** { *; }
-keep class android.hardware.camera2.** { *; }
-dontwarn io.flutter.plugins.camera.**

# ---------- Router OS Client ----------
-keep class router_os_client.** { *; }
-keep class com.github.nassaralshabi.routeros.** { *; }
-dontwarn router_os_client.**

# ---------- MQTT ----------
-keep class mqtt.** { *; }
-keep class org.eclipse.paho.** { *; }
-keep class org.eclipse.paho.client.mqttv3.** { *; }
-dontwarn org.eclipse.paho.**

# ---------- Dio / HTTP ----------
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# ---------- PDF (syncfusion_flutter_pdf + pdf package) ----------
-keep class com.syncfusion.** { *; }
-keep class io.flutter.plugins.syncfusion_pdf.** { *; }
-dontwarn com.syncfusion.**

# ---------- SharedPreferences / Path Provider / File Picker ----------
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.filepicker.** { *; }
-dontwarn io.flutter.plugins.**

# ---------- Network Info Plus ----------
-keep class com.lyokode.locationinfo.** { *; }
-keep class dev.darttools.flutter_android_lifecycle.** { *; }
-dontwarn dev.darttools.**

# ---------- Kotlin / Coroutines ----------
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ---------- Reflection / Annotations ----------
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes RuntimeVisibleTypeAnnotations
-keepattributes RuntimeInvisibleTypeAnnotations

# ---------- Native Methods ----------
-keepclasseswithmembernames class * {
    native <methods>;
}

# ---------- Enums ----------
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ---------- Dart ↔ JS / Plugin Registrant ----------
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ---------- Application Class ----------
-keep class com.mikrotik.manager.MainActivity { *; }
-keep class com.mikrotik.manager.** { *; }

# ---------- Optimization Passes ----------
# Inline small methods (تسريع تنفيذ)
-allowaccessmodification
-repackageclasses ''
-mergeinterfacesaggressively

# إزالة Log.d و Log.v في الإصدار النهائي (تسريع وتقليل حجم)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
