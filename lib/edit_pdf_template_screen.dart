import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/pdf_template.dart';
import 'pdf_templates_screen.dart';
import 'services/pdf_template_preview_server.dart';
import 'services/pdf_template_storage.dart';
import 'snackbar_helpers.dart';
import 'theme/app_theme.dart';

class EditPdfTemplateScreen extends StatefulWidget {
  final List<Map<String, dynamic>> profiles;
  final PdfTemplate? existingTemplate;

  const EditPdfTemplateScreen({
    super.key,
    required this.profiles,
    this.existingTemplate,
  });

  @override
  State<EditPdfTemplateScreen> createState() => _EditPdfTemplateScreenState();
}

class _EditPdfTemplateScreenState extends State<EditPdfTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageKey = GlobalKey();

  File? _imageFile;
  Offset _offset = Offset.zero;
  Offset _normalizedOffset = const Offset(0.5, 0.5);
  double _markerWidth = 100;
  double _markerHeight = 25;
  String? _selectedProfile;
  final _cardsPerPageController = TextEditingController();
  bool _isLoading = false;

  List<String> get _profileNames {
    final names = <String>{};
    for (final profile in widget.profiles) {
      final name = profile['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) names.add(name);
    }
    return names.toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    final template = widget.existingTemplate;
    if (template != null) {
      _selectedProfile = template.profileName;
      _cardsPerPageController.text = template.cardsPerPage.toString();
      _imageFile = File(template.imagePath);
      _normalizedOffset = Offset(template.textXRatio, template.textYRatio);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyNormalizedOffset();
      });
    }
  }

  @override
  void dispose() {
    _cardsPerPageController.dispose();
    super.dispose();
  }

  RenderBox? _imageRenderBox() {
    final renderObject = _imageKey.currentContext?.findRenderObject();
    return renderObject is RenderBox ? renderObject : null;
  }

  void _applyNormalizedOffset() {
    final renderBox = _imageRenderBox();
    if (renderBox == null ||
        renderBox.size.width <= 0 ||
        renderBox.size.height <= 0) {
      return;
    }
    final width = renderBox.size.width;
    final height = renderBox.size.height;
    final safeMarkerWidth = math.min(_markerWidth, width);
    final safeMarkerHeight = math.min(_markerHeight, height);
    final halfWidth = safeMarkerWidth / 2;
    final halfHeight = safeMarkerHeight / 2;
    final desiredX = _normalizedOffset.dx * width;
    final desiredY = _normalizedOffset.dy * height;
    setState(() {
      _markerWidth = safeMarkerWidth;
      _markerHeight = safeMarkerHeight;
      _offset = Offset(
        desiredX.clamp(halfWidth, math.max(halfWidth, width - halfWidth)),
        desiredY.clamp(halfHeight, math.max(halfHeight, height - halfHeight)),
      );
    });
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null || !mounted) return;
      setState(() {
        _imageFile = File(pickedFile.path);
        _offset = Offset.zero;
        _normalizedOffset = const Offset(0.5, 0.5);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyNormalizedOffset();
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'تعذر اختيار صورة القالب: $e');
    }
  }

  Future<PdfTemplate> _buildDraftTemplate({required String imagePath}) async {
    final renderBox = _imageRenderBox();
    if (renderBox == null) {
      throw const FormatException('لم يتم تحميل صورة القالب بعد.');
    }
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw const FileSystemException('صورة القالب غير موجودة.');
    }

    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = await decodeImageFromList(imageBytes);
    if (decodedImage.width <= 0 || decodedImage.height <= 0) {
      throw const FormatException('تعذر قراءة أبعاد صورة القالب.');
    }

    final displayWidth = renderBox.size.width;
    final displayHeight = renderBox.size.height;
    if (displayWidth <= 0 || displayHeight <= 0) {
      throw const FormatException('أبعاد المعاينة غير صالحة.');
    }
    final safeMarkerWidth = _markerWidth.clamp(20.0, displayWidth);
    final safeMarkerHeight = _markerHeight.clamp(10.0, displayHeight);
    final halfWidth = safeMarkerWidth / 2;
    final halfHeight = safeMarkerHeight / 2;
    final safeOffset = Offset(
      _offset.dx.clamp(
        halfWidth,
        math.max(halfWidth, displayWidth - halfWidth),
      ),
      _offset.dy.clamp(
        halfHeight,
        math.max(halfHeight, displayHeight - halfHeight),
      ),
    );

    return PdfTemplate(
      id: widget.existingTemplate?.id,
      profileName: _selectedProfile!.trim(),
      imagePath: imagePath,
      textXRatio: (safeOffset.dx / displayWidth).clamp(0.0, 1.0).toDouble(),
      textYRatio: (safeOffset.dy / displayHeight).clamp(0.0, 1.0).toDouble(),
      cardsPerPage: int.parse(_cardsPerPageController.text.trim()),
      imageWidth: decodedImage.width.toDouble(),
      imageHeight: decodedImage.height.toDouble(),
      markerWidthRatio:
          (safeMarkerWidth / displayWidth).clamp(0.01, 1.0).toDouble(),
      markerHeightRatio:
          (safeMarkerHeight / displayHeight).clamp(0.01, 1.0).toDouble(),
    )..validate();
  }

  Future<void> _previewInBrowser() async {
    if (!_formKey.currentState!.validate()) return;
    final imageFile = _imageFile;
    if (imageFile == null) {
      showErrorSnackBar(context, 'اختر صورة الخلفية أولاً.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final draft = await _buildDraftTemplate(imagePath: imageFile.path);
      final uri = await PdfTemplatePreviewServer.instance.start(
        template: draft,
        sampleCards: const ['10000001', '10000002', '10000003', '10000004'],
      );
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        showErrorSnackBar(context, 'تعذر فتح المعاينة في المتصفح.');
      } else if (mounted) {
        showSuccessSnackBar(context, 'تم تشغيل المعاينة المحلية في المتصفح.');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'تعذر إنشاء المعاينة: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    final imageFile = _imageFile;
    if (imageFile == null) {
      showErrorSnackBar(context, 'الرجاء اختيار صورة وانتظار تحميلها أولاً.');
      return;
    }
    if (!await imageFile.exists()) {
      if (!mounted) return;
      showErrorSnackBar(context, 'صورة القالب غير موجودة في المسار المحدد.');
      return;
    }

    setState(() => _isLoading = true);
    String? newImagePath;
    try {
      final draft = await _buildDraftTemplate(imagePath: imageFile.path);
      final oldTemplate = widget.existingTemplate;
      final keepExistingImage = oldTemplate != null &&
          p.normalize(oldTemplate.imagePath) == p.normalize(imageFile.path) &&
          await File(oldTemplate.imagePath).exists();
      late final File savedImage;
      if (keepExistingImage) {
        savedImage = imageFile;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final extension = p.extension(imageFile.path).toLowerCase();
        final safeExtension =
            const {'.png', '.jpg', '.jpeg', '.webp'}.contains(extension)
                ? extension
                : '.png';
        final fileName =
            'pdf_template_${DateTime.now().microsecondsSinceEpoch}$safeExtension';
        savedImage = await imageFile.copy(p.join(appDir.path, fileName));
      }
      newImagePath = savedImage.path;
      final newTemplate = draft.copyWith(imagePath: savedImage.path);
      await PdfTemplateStorage.save(newTemplate);
      if (oldTemplate != null &&
          oldTemplate.imagePath != newTemplate.imagePath) {
        try {
          final oldImage = File(oldTemplate.imagePath);
          if (await oldImage.exists()) await oldImage.delete();
        } catch (_) {}
      }

      if (!mounted) return;
      showSuccessSnackBar(context, 'تم حفظ قالب PDF والتحقق من بياناته بنجاح.');
      Navigator.of(context).pop();
    } catch (e) {
      final copiedPath = newImagePath;
      if (copiedPath != null &&
          widget.existingTemplate?.imagePath != copiedPath) {
        try {
          final copiedImage = File(copiedPath);
          if (await copiedImage.exists()) await copiedImage.delete();
        } catch (_) {}
      }
      if (mounted) showErrorSnackBar(context, 'فشل حفظ القالب: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _imageKey.currentContext == null) return;
      if (_offset == Offset.zero) _applyNormalizedOffset();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingTemplate == null ? 'إضافة قالب جديد' : 'تعديل قالب',
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري التحقق وحفظ القالب...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue:
                                _profileNames.contains(_selectedProfile)
                                    ? _selectedProfile
                                    : null,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            dropdownColor:
                                Theme.of(context).colorScheme.surface,
                            decoration: const InputDecoration(
                              labelText: 'اختر الفئة (البروفايل)',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _profileNames
                                .map(
                                  (name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => _selectedProfile = value,
                            ),
                            validator: (value) =>
                                value == null ? 'الرجاء اختيار فئة' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cardsPerPageController,
                            decoration: const InputDecoration(
                              labelText: 'عدد الكروت في كل صفحة',
                              helperText: 'من 1 إلى 1000 كرت',
                              prefixIcon: Icon(Icons.view_module_outlined),
                            ),
                            style: TextStyle(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color ??
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              final parsed = int.tryParse(value?.trim() ?? '');
                              if (parsed == null) return 'أدخل رقماً صحيحاً';
                              if (parsed < 1 || parsed > 1000) {
                                return 'يجب أن يكون العدد بين 1 و1000';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'حرك المربع لتحديد منطقة طباعة الرقم',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onPanUpdate: (details) {
                              final renderBox = _imageRenderBox();
                              if (renderBox == null) return;
                              final width = renderBox.size.width;
                              final height = renderBox.size.height;
                              final safeWidth = math.min(_markerWidth, width);
                              final safeHeight =
                                  math.min(_markerHeight, height);
                              final halfWidth = safeWidth / 2;
                              final halfHeight = safeHeight / 2;
                              final next = _offset + details.delta;
                              setState(() {
                                _offset = Offset(
                                  next.dx.clamp(
                                    halfWidth,
                                    math.max(halfWidth, width - halfWidth),
                                  ),
                                  next.dy.clamp(
                                    halfHeight,
                                    math.max(halfHeight, height - halfHeight),
                                  ),
                                );
                                _normalizedOffset = Offset(
                                  _offset.dx / width,
                                  _offset.dy / height,
                                );
                              });
                            },
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).appColors.muted,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _imageFile == null
                                        ? const Center(
                                            child: Text(
                                              'اختر صورة للقالب أولاً',
                                            ),
                                          )
                                        : Image.file(
                                            _imageFile!,
                                            key: _imageKey,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                  if (_imageFile != null)
                                    Positioned(
                                      left: _offset.dx - (_markerWidth / 2),
                                      top: _offset.dy - (_markerHeight / 2),
                                      child: IgnorePointer(
                                        child: Container(
                                          width: _markerWidth,
                                          height: _markerHeight,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color:
                                                  context.theme.appColors.error,
                                              width: 2,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: context.theme.appColors.error
                                                .withAlpha((255 * 0.3).round()),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                'العرض:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _markerWidth.clamp(20, 300),
                                  min: 20,
                                  max: 300,
                                  divisions: 28,
                                  label: _markerWidth.round().toString(),
                                  onChanged: (value) {
                                    setState(() {
                                      _markerWidth = value;
                                      _applyNormalizedOffset();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                'الارتفاع:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _markerHeight.clamp(10, 150),
                                  min: 10,
                                  max: 150,
                                  divisions: 14,
                                  label: _markerHeight.round().toString(),
                                  onChanged: (value) {
                                    setState(() {
                                      _markerHeight = value;
                                      _applyNormalizedOffset();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('اختر/غير صورة القالب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _isLoading || _imageFile == null
                                ? null
                                : _previewInBrowser,
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('معاينة محلية عبر المتصفح'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveTemplate,
                            icon: const Icon(Icons.save),
                            label: const Text('حفظ والتحقق من القالب'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
