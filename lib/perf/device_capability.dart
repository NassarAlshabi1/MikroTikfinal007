// ============================================================
//  DeviceCapability
//  يكشف قدرة الجهاز ويصنّفه: low / mid / high
//  يُستخدم لتعطيل الميزات الثقيلة على الأجهزة الضعيفة
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// مستوى قدرة الجهاز
enum DeviceTier { low, mid, high }

class DeviceCapability {
  DeviceCapability._();
  static final DeviceCapability instance = DeviceCapability._();

  DeviceTier _tier = DeviceTier.mid;
  bool _initialized = false;
  int? _androidSdk;

  DeviceTier get tier => _tier;
  bool get isLowEnd => _tier == DeviceTier.low;
  bool get isHighEnd => _tier == DeviceTier.high;

  /// يجب استدعاؤها مرة واحدة عند بدء التطبيق
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        _androidSdk = info.version.sdkInt;
        // numberOfCores قد لا يكون متاحاً في كل النسخ
        // نعتمد على SDK فقط + heuristic
        // SDK 21-25: غالباً أجهزة ضعيفة (2014-2016)
        // SDK 26-29: متوسطة (2017-2019)
        // SDK 30+: حديثة
        final sdk = _androidSdk ?? 21;
        if (sdk < 26) {
          _tier = DeviceTier.low;
        } else if (sdk < 31) {
          _tier = DeviceTier.mid;
        } else {
          _tier = DeviceTier.high;
        }
      } else if (kIsWeb || Platform.isIOS) {
        _tier = DeviceTier.mid;
      } else {
        _tier = DeviceTier.high;
      }
    } catch (_) {
      // في حال فشل الكشف، افترض جهازاً متوسطاً
      _tier = DeviceTier.mid;
    }

    // على الأجهزة الضعيفة: عطّل بعض الميزات عالمياً
    if (_tier == DeviceTier.low) {
      // عطّل تأثيرات الحركة في الإطار
      // يقلل工作量 الرسم بشكل كبير
      debugPrint('DeviceCapability: low-end device detected, optimizing');
    }
  }

  /// مدة الحركة الافتراضية حسب الجهاز
  Duration get animationDuration {
    switch (_tier) {
      case DeviceTier.low:
        return const Duration(milliseconds: 120);  // أسرع بكثير
      case DeviceTier.mid:
        return const Duration(milliseconds: 200);
      case DeviceTier.high:
        return const Duration(milliseconds: 300);
    }
  }

  /// هل نُفعّل الـ repaginate الكامل (cache للصفحات السابقة)؟
  bool get enableFullPaginationCache => _tier != DeviceTier.low;

  /// عدد العناصر المُخبّرة في ListView
  double get listViewCacheExtent {
    switch (_tier) {
      case DeviceTier.low:
        return 100;     // فقط ما يظهر + قليل
      case DeviceTier.mid:
        return 250;
      case DeviceTier.high:
        return 500;
    }
  }

  /// عطّل تأثيرات الـ shimmer / blur على الأجهزة الضعيفة
  bool get enableShimmerEffects => _tier != DeviceTier.low;
  bool get enableBlurEffects => _tier == DeviceTier.high;
  bool get enableComplexAnimations => _tier != DeviceTier.low;

  /// دقة الصور المُخبّاة (cacheWidth/Height)
  int? get imageCacheWidth => _tier == DeviceTier.low ? 200 : null;

  /// هل نُحمّل ML Kit OCR مسبقاً؟
  bool get preloadMlKit => _tier == DeviceTier.high;

  /// هل نُفعّل fancy page transitions؟
  bool get enablePageTransitions => _tier != DeviceTier.low;
}

/// Helper سريع للوصول من أي مكان
DeviceTier get currentDeviceTier => DeviceCapability.instance.tier;
bool get isLowEndDevice => DeviceCapability.instance.isLowEnd;
