import '../api/maintenance_api.dart';
import '../models/telegram_settings.dart';
import 'telegram_health.dart';
import 'telegram_messages.dart';
import 'telegram_report_service.dart';

/// **فاحص أجهزة البث (Netwatch)** — يراقب أجهزة الجيران (Neighbor Discovery)
/// عبر ping دوري، ويُرسل إشعارًا فوريًا عند انقطاع أي جهاز أو عودته.
///
/// • الفحص يجري كل دقيقة (من [TelegramScheduler]).
/// • أول فحص يبني **خط الأساس** بصمت (بلا إشعارات) لتفادي الإزعاج عند الإقلاع.
/// • عدد الأجهزة محدود لتفادي إثقال الراوتر.
class TelegramNetwatch {
  const TelegramNetwatch._();

  /// أقصى عدد أجهزة يُفحص في الدورة.
  static const int maxDevices = 15;

  static final Map<String, bool> _state = {};
  static final Map<String, String> _names = {};
  static bool _baselineReady = false;
  static bool _scanning = false;

  static int lastTotal = 0;
  static int lastOnline = 0;
  static int lastOffline = 0;
  static DateTime? lastScanAt;

  static bool get hasBaseline => _baselineReady;

  /// حالة الأجهزة المعروفة (العنوان ⇒ متصل؟).
  static Map<String, bool> get state => Map<String, bool>.unmodifiable(_state);

  /// منع تشغيل فحصين بالتوازي.
  static bool get isScanning => _scanning;

  /// هل نعرف حجم الشبكة المقاس؟
  static bool get hasData => lastScanAt != null;

  /// فحص واحد لأجهزة البث. يُرجع عدد الأجهزة المنقطعة.
  ///
  /// [notify] = false ⇒ يحدّث الحالة بلا إرسال إشعارات (يُستعمل في التقارير).
  static Future<int> scan({
    TelegramSettings? provided,
    bool notify = true,
  }) async {
    if (_scanning) return lastOffline;
    _scanning = true;
    try {
      final settings = provided ?? await TelegramSettingsStore.load();

      final neighbors = await MaintenanceApi.neighbors();
      final rows = (neighbors.status && neighbors.data != null)
          ? neighbors.data!
          : const <Map<String, String>>[];

      // تجميع الأجهزة (عنوان ⇒ اسم) بلا تكرار
      final devices = <String, String>{};
      for (final row in rows) {
        final address = (row['address'] ?? '').trim();
        if (address.isEmpty) continue;
        final name = (row['identity'] ?? '').trim().isNotEmpty
            ? row['identity']!.trim()
            : ((row['mac-address'] ?? '').trim().isNotEmpty
                ? row['mac-address']!.trim()
                : address);
        devices.putIfAbsent(address, () => name);
        if (devices.length >= maxDevices) break;
      }

      if (devices.isEmpty) {
        lastTotal = 0;
        lastOnline = 0;
        lastOffline = 0;
        lastScanAt = DateTime.now();
        return 0;
      }

      var online = 0;
      var offline = 0;
      final changes = <MapEntry<String, bool>>[];

      for (final entry in devices.entries) {
        final address = entry.key;
        final name = entry.value;

        final ping = await MaintenanceApi.ping(address: address, count: 1);
        final reachable = ping.status &&
            TelegramHealth.pingReachable(
              ping.data ?? const <Map<String, String>>[],
            );

        if (reachable) {
          online++;
        } else {
          offline++;
        }

        final before = _state[address];
        _state[address] = reachable;
        _names[address] = name;

        if (_baselineReady && before != null && before != reachable) {
          changes.add(MapEntry(address, reachable));
        }
      }

      lastTotal = devices.length;
      lastOnline = online;
      lastOffline = offline;
      lastScanAt = DateTime.now();

      final firstRun = !_baselineReady;
      _baselineReady = true;

      // لا إشعارات في أول دورة (خط الأساس) ولا عند تعطيل الميزة
      if (notify &&
          !firstRun &&
          changes.isNotEmpty &&
          settings.isFeatureEnabled('netwatch')) {
        for (final change in changes) {
          await TelegramReportService.sendText(
            TelegramMessages.netwatch(
              device: _names[change.key] ?? change.key,
              ip: change.key,
              isUp: change.value,
            ),
            settings,
          );
        }
      }

      return offline;
    } catch (_) {
      // انقطاع الاتصال بالراوتر ليس حدث انقطاع جهاز ⇒ لا إشعار
      return lastOffline;
    } finally {
      _scanning = false;
    }
  }

  /// إعادة الصفر (تفيد في الاختبار/عند تغيير الراوتر).
  static void reset() {
    _state.clear();
    _names.clear();
    _baselineReady = false;
    lastTotal = 0;
    lastOnline = 0;
    lastOffline = 0;
    lastScanAt = null;
  }
}
