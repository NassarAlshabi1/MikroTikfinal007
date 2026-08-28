// ============================================================
//  Result<E, S> — نمط Either للتعامل الوظيفي مع الأخطاء
//
//  تطبّق معايير flutter-apply-architecture-best-practices:
//  ✅ Functional Error Handling: Either<Failure, T> بدل استثناءات
//  ✅ Sealed Classes: لـ exhaustive pattern matching
//  ✅ Never throw exceptions across layer boundaries
//  ✅ Dart 3 pattern matching
// ============================================================

/// نتيجة عملية قد تنجح أو تفشل
///
/// [E] نوع الخطأ (Failure)
/// [S] نوع النجاح (Success value)
sealed class Result<E, S> {
  const Result();

  /// هل نجحت العملية؟
  bool get isSuccess => this is Success<E, S>;

  /// هل فشلت العملية؟
  bool get isFailure => this is Failure<E, S>;

  /// يحصل على القيمة إن نجحت، أو يرجع [orElse]
  S getOrElse(S Function() orElse) {
    return switch (this) {
      Success(:final value) => value,
      Failure() => orElse(),
    };
  }

  /// يحصل على القيمة إن نجحت، أو قيمة افتراضية
  S getOrDefault(S defaultValue) => getOrElse(() => defaultValue);

  /// يحول القيمة الناجحة عبر [mapper]
  Result<E, T> map<T>(T Function(S value) mapper) {
    return switch (this) {
      Success(:final value) => Success(mapper(value)),
      Failure(:final error) => Failure(error),
    };
  }

  /// يحول الخطأ عبر [mapper]
  Result<T, S> mapError<T>(T Function(E error) mapper) {
    return switch (this) {
      Success(:final value) => Success(value),
      Failure(:final error) => Failure(mapper(error)),
    };
  }

  /// يطبّق [onSuccess] أو [onFailure] حسب الحالة
  R when<R>({
    required R Function(S value) onSuccess,
    required R Function(E error) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }
}

/// نتيجة ناجحة
final class Success<E, S> extends Result<E, S> {
  final S value;

  const Success(this.value);
}

/// نتيجة فاشلة
final class Failure<E, S> extends Result<E, S> {
  final E error;

  const Failure(this.error);
}

// ============================================================
//  MikrotikError — sealed class لأخطاء MikroTik الشائعة
// ============================================================

/// خطأ من MikroTik — exhaustive pattern matching
sealed class MikrotikError {
  const MikrotikError();

  /// رسالة معروضة للمستخدم (آمنة للعرض)
  String get userMessage;
}

/// مهلة اتصال
final class TimeoutMikrotikError extends MikrotikError {
  const TimeoutMikrotikError();
  @override
  String get userMessage =>
      'انتهت مهلة الاتصال. تأكد من أن الراوتر يعمل وقابل للوصول.';
}

/// رفض الاتصال
final class ConnectionRefusedMikrotikError extends MikrotikError {
  const ConnectionRefusedMikrotikError();
  @override
  String get userMessage =>
      'تم رفض الاتصال. تأكد من أن المنفذ (8728) مفتوح على الراوتر.';
}

/// فشل المصادقة
final class AuthenticationFailedMikrotikError extends MikrotikError {
  const AuthenticationFailedMikrotikError();
  @override
  String get userMessage =>
      'بيانات اعتماد خاطئة. تحقق من اسم المستخدم وكلمة المرور.';
}

/// بيانات اعتماد ناقصة
final class CredentialsMissingMikrotikError extends MikrotikError {
  const CredentialsMissingMikrotikError();
  @override
  String get userMessage =>
      'بيانات اعتماد MikroTik غير مكتملة. سجّل الدخول أولاً.';
}

/// خطأ شبكي عام
final class NetworkMikrotikError extends MikrotikError {
  final String? detail;
  const NetworkMikrotikError([this.detail]);
  @override
  String get userMessage => detail != null
      ? 'خطأ شبكي: $detail'
      : 'خطأ شبكي غير محدد. تحقق من اتصالك بالإنترنت.';
}

/// خطأ غير معروف
final class UnknownMikrotikError extends MikrotikError {
  final String message;
  const UnknownMikrotikError(this.message);
  @override
  String get userMessage => 'خطأ غير متوقع: $message';
}

// ============================================================
//  أدوات مساعدة لتحويل الاستثناءات إلى MikrotikError
// ============================================================

/// يحول استثناء MikroTik عام إلى MikrotikError مناسب
MikrotikError mapExceptionToMikrotikError(Object error) {
  final errorStr = error.toString().toLowerCase();

  // التحقق من 'missing' أو 'not found' أولاً (قبل 'auth' و 'credentials')
  // لأن 'Credentials missing' تحتوي على كلتا الكلمتين
  if (errorStr.contains('missing') || errorStr.contains('not found')) {
    return const CredentialsMissingMikrotikError();
  }
  if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
    return const TimeoutMikrotikError();
  }
  if (errorStr.contains('connection refused') ||
      errorStr.contains('socket') ||
      errorStr.contains('connect')) {
    return const ConnectionRefusedMikrotikError();
  }
  if (errorStr.contains('login') ||
      errorStr.contains('auth') ||
      errorStr.contains('credentials')) {
    return const AuthenticationFailedMikrotikError();
  }
  return UnknownMikrotikError(error.toString());
}
