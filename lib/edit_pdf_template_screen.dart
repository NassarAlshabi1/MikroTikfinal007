import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:url_launcher/url_launcher.dart';

import 'mikrotik_connector.dart';
import 'models/pdf_template.dart';
import 'pdf_templates_screen.dart';
import 'services/card_persistence_service.dart';
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
  bool _isLoadingProfiles = false;
  String? _profileLoadError;
  late List<String> _availableProfileNames;

  List<String> get _profileNames => _availableProfileNames;

  List<String> _normalizeProfileNames(Iterable<Map<String, dynamic>> profiles) {
    final names = <String>{};
    for (final profile in profiles) {
      final name = profile['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) names.add(name);
    }
    return names.toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _availableProfileNames = _normalizeProfileNames(widget.profiles);
    unawaited(_loadProfilesFromRouter());
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

  Future<void> _loadProfilesFromRouter() async {
    if (_isLoadingProfiles) return;
    if (mounted) {
      setState(() {
        _isLoadingProfiles = true;
        _profileLoadError = null;
      });
    }

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      // نفس أمر RouterOS المستخدم في main؛ بعض إصدارات v6 لا تتعامل
      // بشكل متسق مع proplist عند جلب بروفايلات Hotspot.
      final response = await client.talk(['/ip/hotspot/user/profile/print']);
      final profiles = response
          .map((profile) => Map<String, dynamic>.from(profile))
          .toList(growable: false);
      final names = _normalizeProfileNames(profiles);
      if (names.isEmpty) {
        throw const FormatException('لم يعثر MikroTik على أي بروفايل Hotspot.');
      }
      try {
        await CardPersistenceService.cacheHotspotProfiles(profiles);
      } catch (e) {
        debugPrint('[PdfTemplate] profile cache error: $e');
      }
      if (!mounted) return;
      setState(() {
        // عند نجاح الجلب تصبح نتيجة MikroTik هي المصدر الأساسي، مع الحفاظ
        // على قائمة البداية فقط أثناء الاتصال أو عند فشله.
        _availableProfileNames = names;
        if (_selectedProfile != null && !names.contains(_selectedProfile)) {
          _selectedProfile = null;
        }
        _profileLoadError = null;
      });
    } catch (e) {
      debugPrint('[PdfTemplate] profile loading error: $e');
      if (mounted) {
        setState(() {
          _profileLoadError =
              'تعذر جلب بروفايلات MikroTik؛ ستُستخدم القائمة المتاحة مؤقتاً.';
        });
      }
    } finally {
      MikrotikConnector.release(client);
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    String? helperText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final colors = Theme.of(context).appColors;
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.outline, width: 1.2),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.inputFocusedBorder, width: 2),
    );
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      filled: true,
      fillColor: colors.inputBackground,
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: colors.primary,
        fontWeight: FontWeight.bold,
      ),
      helperStyle: TextStyle(color: colors.textSecondary),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: colors.primary, size: 23),
      suffixIcon: suffixIcon,
      border: enabledBorder,
      enabledBorder: enabledBorder,
      focusedBorder: focusedBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
    );
  }

  TextStyle _fieldTextStyle() {
    return TextStyle(
      color: Theme.of(context).appColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
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
      final picked = File(pickedFile.path);
      final byteLength = await picked.length();
      if (!mounted) return;
      if (byteLength <= 0 || byteLength > PdfTemplate.maxImageBytes) {
        showErrorSnackBar(context, 'حجم الصورة يجب ألا يتجاوز 12 ميغابايت.');
        return;
      }
      setState(() {
        _imageFile = picked;
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
    final byteLength = await imageFile.length();
    if (byteLength <= 0 || byteLength > PdfTemplate.maxImageBytes) {
      throw const FileSystemException(
          'حجم صورة القالب يجب ألا يتجاوز 12 ميغابايت.');
    }

    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = await decodeImageFromList(imageBytes);
    if (decodedImage.width <= 0 || decodedImage.height <= 0) {
      throw const FormatException('تعذر قراءة أبعاد صورة القالب.');
    }
    if (decodedImage.width > PdfTemplate.maxImageDimension ||
        decodedImage.height > PdfTemplate.maxImageDimension) {
      throw const FormatException('أبعاد صورة القالب أكبر من الحد المسموح.');
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
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                            style: _fieldTextStyle(),
                            dropdownColor:
                                Theme.of(context).colorScheme.surface,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Theme.of(context).appColors.primary,
                            ),
                            decoration: _fieldDecoration(
                              labelText: 'اختر الفئة (بروفايل MikroTik)',
                              helperText: _isLoadingProfiles
                                  ? 'جاري جلب فئات الكروت من MikroTik...'
                                  : _profileLoadError ??
                                      'المصدر: /ip/hotspot/user/profile/print',
                              prefixIcon: Icons.category_rounded,
                              suffixIcon: IconButton(
                                tooltip: 'تحديث البروفايلات من MikroTik',
                                onPressed: _isLoadingProfiles
                                    ? null
                                    : () => _loadProfilesFromRouter(),
                                color: Theme.of(context).appColors.primary,
                                icon: _isLoadingProfiles
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Theme.of(context)
                                              .appColors
                                              .primary,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded),
                              ),
                            ),
                            hint: Text(
                              _profileNames.isEmpty
                                  ? 'لا توجد بروفايلات متاحة'
                                  : 'اختر فئة الكروت',
                              style: TextStyle(
                                color:
                                    Theme.of(context).appColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            items: _profileNames
                                .map(
                                  (name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(
                                      name,
                                      style: _fieldTextStyle(),
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
                            decoration: _fieldDecoration(
                              labelText: 'عدد الكروت في كل صفحة',
                              helperText: 'من 1 إلى 1000 كرت',
                              prefixIcon: Icons.view_module_rounded,
                            ),
                            style: _fieldTextStyle(),
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
                          Text(
                            'حرك المربع لتحديد منطقة طباعة الرقم',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).appColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                                  color: Theme.of(context).appColors.outline,
                                  width: 1.3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _imageFile == null
                                        ? Center(
                                            child: Text(
                                              'اختر صورة للقالب أولاً',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .appColors
                                                    .textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
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
                              Text(
                                'العرض:',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).appColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
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
                              Text(
                                'الارتفاع:',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).appColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
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
