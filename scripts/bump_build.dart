// ============================================================
//  bump_build.dart — رفع رقم إصدار التطبيق في pubspec.yaml
//
//  الاستخدام:
//    dart run scripts/bump_build.dart            # يرفع رقم البناء: 1.0.0+1 → 1.0.0+2
//    dart run scripts/bump_build.dart patch      # 1.0.0+1 → 1.0.1+2
//    dart run scripts/bump_build.dart minor      # 1.0.0+1 → 1.1.0+2
//    dart run scripts/bump_build.dart major      # 1.0.0+1 → 2.0.0+2
//
//  يعمل على كل المنصّات (Android / iOS / Web / Desktop) لأنه يعدّل
//  المصدر الوحيد للحقيقة: pubspec.yaml. مناسب أيضاً لأنظمة CI.
// ============================================================

import 'dart:io';

void main(List<String> args) {
  final part = args.isNotEmpty ? args.first.toLowerCase() : 'build';

  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    stderr.writeln('❌ لم أجد pubspec.yaml — شغّل الأمر من جذر المشروع.');
    exit(1);
  }

  final content = file.readAsStringSync();
  final regex = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
      multiLine: true);
  final match = regex.firstMatch(content);

  if (match == null) {
    stderr.writeln('❌ صيغة version غير متوقعة. المطلوب: version: x.y.z+N');
    exit(1);
  }

  var major = int.parse(match.group(1)!);
  var minor = int.parse(match.group(2)!);
  var patch = int.parse(match.group(3)!);
  var build = int.parse(match.group(4)!);

  final oldVersion = '$major.$minor.$patch+$build';

  switch (part) {
    case 'major':
      major += 1;
      minor = 0;
      patch = 0;
      build += 1;
      break;
    case 'minor':
      minor += 1;
      patch = 0;
      build += 1;
      break;
    case 'patch':
      patch += 1;
      build += 1;
      break;
    case 'build':
      build += 1;
      break;
    default:
      stderr.writeln('❌ خيار غير معروف: $part (المتاح: build | patch | minor | major)');
      exit(1);
  }

  final newVersion = '$major.$minor.$patch+$build';
  final updated =
      content.replaceFirst(regex, 'version: $newVersion');
  file.writeAsStringSync(updated);

  stdout.writeln('✅ تم رفع الإصدار: $oldVersion  →  $newVersion');
}
