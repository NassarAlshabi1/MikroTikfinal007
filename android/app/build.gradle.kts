import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.mikrotik_manager"

    // ==================== تحديثات الأداء ====================
    compileSdk = 36
    // ==========================================================

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.mikrotik_manager"
        minSdk = 21
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName

        // دعم الأجهزة القديمة 32-bit + الحديثة 64-bit
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }

        // تمرير حجم رمز الصورة كـ resValue لتقليل الذاكرة
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    // فصل APK لكل معمارية → تنزيل أصغر بكثير على كل جهاز
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a")
            isUniversalApk = true  // APK موحد كخيار احتياطي
        }
    }

    buildTypes {
        release {
            // توقيع مؤقت (يجب استبداله لاحقاً)
            signingConfig = signingConfigs.getByName("debug")

            // ===== تحسينات R8 / ProGuard (الأهم للأجهزة الضعيفة) =====
            isMinifyEnabled = true       // إزالة الكود الميت
            isShrinkResources = true     // إزالة الموارد غير المستخدمة
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // =========================================================

            // خصائص الـ Build للإصدار
            buildConfigField("Boolean", "DEBUG_MODE", "false")
        }

        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            buildConfigField("Boolean", "DEBUG_MODE", "true")
        }

        profile {
            isMinifyEnabled = false
            isShrinkResources = false
            buildConfigField("Boolean", "DEBUG_MODE", "false")
        }
    }

    // تسريع البناء
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module",
                "META-INF/versions/**"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {}
