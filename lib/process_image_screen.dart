import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'perf/device_capability.dart';

import 'theme/app_theme.dart';

class ProcessImageScreen extends StatefulWidget {
  final String imagePath;
  final String prefix;
  final int length;
  final int total;

  const ProcessImageScreen({
    super.key,
    required this.imagePath,
    required this.prefix,
    required this.length,
    required this.total,
  });

  @override
  State<ProcessImageScreen> createState() => _ProcessImageScreenState();
}

class _ProcessImageScreenState extends State<ProcessImageScreen> {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  String _status = 'جاري معالجة الصورة...';

  @override
  void initState() {
    super.initState();
    // أجّل المعالجة الثقيلة حتى نهاية الإطار لتفادي jank في الـ build الأولي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _processImage();
    });
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _processImage() async {
    try {
      // التحقق من وجود الملف قبل محاولة قراءته
      // (يمنع PathNotFoundException ويعطي رسالة واضحة للمستخدم)
      final imageFile = File(widget.imagePath);
      if (!await imageFile.exists()) {
        throw Exception('ملف الصورة غير موجود: ${widget.imagePath}');
      }

      // Image is already cropped and rectified by the document scanner.
      // Read image from file
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('فشل فك تشفير الصورة — الملف تالف أو غير مدعوم');
      }

      // 1. Convert to grayscale
      if (!mounted) return;
      setState(() {
        _status = 'تحويل الصورة إلى أبيض وأسود...';
      });
      final grayscaleImage = img.grayscale(originalImage);

      // 2. Adjust contrast
      if (!mounted) return;
      setState(() {
        _status = 'تحسين وضوح الأرقام...';
      });
      final contrastImage = img.adjustColor(grayscaleImage, contrast: 1.5);

      // Save the processed image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, 'processed_image.jpg');
      await File(tempPath).writeAsBytes(img.encodeJpg(contrastImage));

      // 3. Perform OCR on the processed image
      if (!mounted) return;
      setState(() {
        _status = 'جاري استخراج الأرقام...';
      });
      final inputImage = InputImage.fromFilePath(tempPath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final RegExp numberRegExp = RegExp(r'\d+');
      final RegExp nonDigitRegExp = RegExp(r'[^0-9]');
      final Set<String> cardNumbers = {};
      final int targetLength = widget.length;
      final String targetPrefix = widget.prefix;
      final int targetTotal = widget.total;

      for (final TextBlock block in recognizedText.blocks) {
        for (final TextLine line in block.lines) {
          final String cleanedLine = line.text.replaceAll(nonDigitRegExp, '');
          final matches = numberRegExp.allMatches(cleanedLine);
          for (final m in matches) {
            final numberStr = m.group(0)!;
            if (numberStr.length == targetLength &&
                numberStr.startsWith(targetPrefix)) {
              cardNumbers.add(numberStr);
              if (cardNumbers.length >= targetTotal) {
                break;
              }
            }
          }
          if (cardNumbers.length >= targetTotal) break;
        }
        if (cardNumbers.length >= targetTotal) break;
      }

      if (!mounted) return;
      Navigator.pop(context, cardNumbers.toList());
    } on PathNotFoundException catch (e) {
      // خطأ محدد: الملف غير موجود (قد يحدث لو حُذف بعد اختياره)
      debugPrint('PathNotFoundException: $e');
      if (mounted) {
        _showErrorAndPop('ملف الصورة غير موجود. قد يكون تم حذفه أو نقله.');
      }
    } on FormatException catch (e) {
      debugPrint('FormatException: $e');
      if (mounted) {
        _showErrorAndPop('صيغة الصورة غير مدعومة. استخدم PNG أو JPG.');
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        _showErrorAndPop('فشل معالجة الصورة: $e');
      }
    }
  }

  /// يعرض رسالة خطأ للمستخدم ثم يعود بنتيجة فارغة
  void _showErrorAndPop(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).appColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
    Navigator.pop(context, []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معالجة الصورة'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: RepaintBoundary(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: DeviceCapability.instance.isLowEnd ? 2 : 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(_status),
              const SizedBox(height: 10),
              const Text('العملية قد تستغرق بعض الوقت...'),
            ],
          ),
        ),
      ),
    );
  }
}
