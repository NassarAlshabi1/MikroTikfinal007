import 'package:mikronet/api/database_api.dart';
import 'package:mikronet/api/router_api.dart';
import 'package:mikronet/services/mikrotik_client.dart';
import 'package:mikronet/models/response.dart';
import 'package:mikronet/models/selles_model.dart';

class ReportsApi {

  // دالة مساعدة لتحويل أي صيغة لتاريخ الدفع من RouterOS إلى DateTime بدقة متناهية
  static DateTime? parsePaymentDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;

    try {
      final clean = dateStr.trim();

      // صيغة ISO أو YYYY-MM-DD أو YYYY/MM/DD
      if (clean.contains('-') || (clean.contains('/') && RegExp(r'^\d{4}').hasMatch(clean))) {
        final normalized = clean.replaceAll('/', '-');
        final dt = DateTime.tryParse(normalized);
        if (dt != null) return dt;
      }

      // صيغة RouterOS الافتراضية: "jul/16/2025 11:32:32" أو "jul/16/2025"
      final parts = clean.split(' ');
      final dateParts = parts[0].split('/');
      if (dateParts.length == 3) {
        const months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
        };

        int? month;
        int? day;
        int? year;

        // إذا كان الشهر نصاً (jul)
        final monthStr = dateParts[0].toLowerCase();
        if (months.containsKey(monthStr)) {
          month = months[monthStr];
          day = int.tryParse(dateParts[1]);
          year = int.tryParse(dateParts[2]);
        } else {
          // إذا كان اليوم أو السنة أولاً
          if (dateParts[0].length == 4) {
            year = int.tryParse(dateParts[0]);
            month = int.tryParse(dateParts[1]);
            day = int.tryParse(dateParts[2]);
          } else {
            month = int.tryParse(dateParts[0]);
            day = int.tryParse(dateParts[1]);
            year = int.tryParse(dateParts[2]);
          }
        }

        if (year != null && month != null && day != null) {
          int hour = 0;
          int minute = 0;
          int second = 0;

          if (parts.length > 1) {
            final timeParts = parts[1].split(':');
            if (timeParts.isNotEmpty) hour = int.tryParse(timeParts[0]) ?? 0;
            if (timeParts.length > 1) minute = int.tryParse(timeParts[1]) ?? 0;
            if (timeParts.length > 2) second = int.tryParse(timeParts[2]) ?? 0;
          }

          return DateTime(year, month, day, hour, minute, second);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List> getPayments() async {
    try {
      if (MikrotikClient.version == 7) {
        // في v7 يتم فحص جلسات أو مدفوعات v7
        return await MikrotikClient.printData(
          commands: ["/user-manager/payment/print"],
          fields: "user,trans-start,price",
          tag: "v7_payments",
        );
      }
      return await MikrotikClient.printData(
        commands: ["/tool/user-manager/payment/print"],
        fields: "user,trans-start,price",
        tag: "v6_payments",
      );
    } catch (_) {
      return [];
    }
  }

  static Future<List> getProfiles() async {
    try {
      if (MikrotikClient.version == 7) {
        return await MikrotikClient.printData(
          commands: ["/user-manager/profile/print"],
          fields: "name,price",
        );
      }
      return await MikrotikClient.printData(
        commands: ["/tool/user-manager/profile/print"],
        fields: "name,price",
      );
    } catch (_) {
      return [];
    }
  }

  /// مزامنة سجلات المبيعات من المايكروتك وتخزينها محلياً في SQLite دون أي تكرار
  /// المبيعات المحفوظة تبقى دائمة ولا تتأثر بحذف الكروت المنتهية أو الجلسات
  static Future<AppResponse<int>> syncSalesFromMikrotik() async {
    try {
      final payments = await getPayments();
      final profiles = await getProfiles();

      String routerSerial = "";
      try {
        final serialRes = await RouterApi.getRouterSerial();
        if (serialRes.status && serialRes.data != null) {
          routerSerial = serialRes.data!;
        }
      } catch (_) {}

      int newInserted = 0;

      if (payments.isNotEmpty) {
        final List<Map<String, dynamic>> rowsToInsert = [];

        for (final p in payments) {
          final user = p['user']?.toString() ?? '';
          if (user.isEmpty) continue;

          final dateStr = p['trans-start']?.toString() ?? '';
          final dt = parsePaymentDate(dateStr) ?? DateTime.now();

          double rawPrice = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
          double calculatedPrice = rawPrice > 1000 ? (rawPrice / 100.0) : rawPrice;

          // البحث عن اسم الباقة
          Map? matchedProfile = profiles.cast<Map?>().firstWhere(
            (pr) {
              if (pr == null || pr['price'] == null) return false;
              double pPrice = double.tryParse(pr['price'].toString()) ?? -1;
              return calculatedPrice == pPrice || rawPrice == pPrice;
            },
            orElse: () => null,
          );

          String profileName = matchedProfile != null ? (matchedProfile['name']?.toString() ?? 'افتراضي') : 'افتراضي';

          rowsToInsert.add({
            'card_username': user,
            'profile_name': profileName,
            'price': calculatedPrice,
            'sale_date': dateStr.isNotEmpty ? dateStr : "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}",
            'timestamp': dt.millisecondsSinceEpoch,
            'router_serial': routerSerial,
            'source': 'usermanager',
          });
        }

        if (rowsToInsert.isNotEmpty) {
          for (final row in rowsToInsert) {
            try {
              final userEscaped = row['card_username'].toString().replaceAll("'", "''");
              final profEscaped = row['profile_name'].toString().replaceAll("'", "''");
              final dateEscaped = row['sale_date'].toString().replaceAll("'", "''");
              final serialEscaped = row['router_serial'].toString().replaceAll("'", "''");
              final priceVal = row['price'];
              final tsVal = row['timestamp'];

              final sql = '''
                INSERT OR IGNORE INTO sales_records 
                (card_username, profile_name, price, sale_date, timestamp, router_serial, source)
                VALUES ('$userEscaped', '$profEscaped', $priceVal, '$dateEscaped', $tsVal, '$serialEscaped', 'usermanager')
              ''';
              final res = await DBApi.insert("sales_records", row);
              if (res > 0) newInserted++;
            } catch (_) {}
          }
        }
      }

      return AppResponse<int>(
        status: true,
        message: "تمت المزامنة بنجاح",
        data: newInserted,
      );
    } catch (e) {
      return AppResponse<int>(
        status: false,
        message: "خطأ أثناء المزامنة: $e",
      );
    }
  }

  /// جلب تقرير المبيعات المفلتر من قاعدة البيانات المحلية الدائمة
  static Future<AppResponse<List<SellesReportModel>>> getStoredSalesReport({
    DateTime? from,
    DateTime? to,
    String? profileFilter,
    String? searchQuery,
  }) async {
    try {
      final List<String> conditions = [];

      if (from != null) {
        final startOfDay = DateTime(from.year, from.month, from.day, 0, 0, 0);
        conditions.add("timestamp >= ${startOfDay.millisecondsSinceEpoch}");
      }

      if (to != null) {
        final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
        conditions.add("timestamp <= ${endOfDay.millisecondsSinceEpoch}");
      }

      if (profileFilter != null && profileFilter.isNotEmpty && profileFilter != "الكل") {
        final escapedProfile = profileFilter.replaceAll("'", "''");
        conditions.add("profile_name = '$escapedProfile'");
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final cleanSearch = searchQuery.trim().replaceAll("'", "''");
        conditions.add("(card_username LIKE '%$cleanSearch%' OR profile_name LIKE '%$cleanSearch%')");
      }

      final whereClause = conditions.isNotEmpty ? conditions.join(" AND ") : null;
      final rows = await DBApi.select("sales_records", whereClause, "*", "timestamp DESC");

      final List<SellesReportModel> result = rows.map((r) => SellesReportModel.fromDatabase(r)).toList();

      return AppResponse<List<SellesReportModel>>(
        status: true,
        message: "done",
        data: result,
      );
    } catch (e) {
      return AppResponse<List<SellesReportModel>>(
        status: false,
        message: e.toString(),
      );
    }
  }

  /// جلب قائمة جميع الباقات المتاحة (من المبيعات والراوتر) للفلترة بها
  static Future<List<String>> getAvailableProfileNames() async {
    final Set<String> profilesSet = {};
    try {
      final rows = await DBApi.select("sales_records", null, "DISTINCT profile_name as prof");
      for (final r in rows) {
        final name = r['prof']?.toString();
        if (name != null && name.isNotEmpty) profilesSet.add(name);
      }
    } catch (_) {}

    try {
      final routerProfiles = await getProfiles();
      for (final p in routerProfiles) {
        final name = p['name']?.toString();
        if (name != null && name.isNotEmpty) profilesSet.add(name);
      }
    } catch (_) {}

    final list = profilesSet.toList()..sort();
    return ["الكل", ...list];
  }

  // تم التعديل: إرجاع AppResponse محدد النوع <SystemStateModel>
  static Future<AppResponse<SystemStateModel>> getSystemState() async {
    try {
      var response = await MikrotikClient.printData(
        commands: ["/system/resource/print"],
      );

      if (response.isNotEmpty) {
        var systemDataMap = response.first as Map;
        SystemStateModel model = SystemStateModel.fromMikrotik(systemDataMap);
        return AppResponse<SystemStateModel>(status: true, message: "done", data: model);
      } else {
        return AppResponse<SystemStateModel>(status: false, message: "لا توجد بيانات متاحة لحالة النظام");
      }
    } catch (e) {
      return AppResponse<SystemStateModel>(status: false, message: e.toString());
    }
  }
}
