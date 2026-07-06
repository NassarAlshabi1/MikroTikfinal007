import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'perf/device_capability.dart';

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
      // Image is already cropped and rectified by the document scanner.
      // Read image from file
      final imageBytes = await File(widget.imagePath).readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception("Failed to decode image");
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
    } catch (e) {
      debugPrint("Error processing image: $e");
      if (mounted) Navigator.pop(context, []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معالجة الصورة'),
        backgroundColor: Theme.of(context).cardColor,
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
