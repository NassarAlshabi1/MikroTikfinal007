// edit_pdf_template_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'snackbar_helpers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'models/pdf_template.dart';
import 'mikrotik_connector.dart';
import 'pdf_templates_screen.dart';
import 'services/pdf_template_storage.dart';

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

  double _markerWidth = 100.0;
  double _markerHeight = 25.0;

  String? _selectedProfile;
  final _cardsPerPageController = TextEditingController();
  List<String> _routerProfiles = const [];
  bool _isLoading = false;
  bool _isLoadingProfiles = false;
  String? _profileLoadError;

  @override
  void initState() {
    super.initState();
    if (widget.existingTemplate != null) {
      final t = widget.existingTemplate!;
      _selectedProfile = t.profileName;
      _cardsPerPageController.text = t.cardsPerPage.toString();
      _imageFile = File(t.imagePath);
      _normalizedOffset = Offset(t.textXRatio, t.textYRatio);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyNormalizedOffset();
      });
    }
    unawaited(_loadProfilesFromRouter());
  }

  @override
  void dispose() {
    _cardsPerPageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfilesFromRouter() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfiles = true;
      _profileLoadError = null;
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      final response = await client.talk([
        '/tool/user-manager/profile/print',
        '=.proplist=name',
      ]).timeout(const Duration(seconds: 20));

      final names = response
          .whereType<Map>()
          .map((profile) => profile['name']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (names.isEmpty) {
        throw const FormatException(
          'لم يعثر User Manager على أي فئة بروفايل.',
        );
      }

      if (!mounted) return;
      setState(() {
        _routerProfiles = names;
        _isLoadingProfiles = false;
        if (_selectedProfile != null && !names.contains(_selectedProfile)) {
          _selectedProfile = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfiles = false;
        _profileLoadError = 'تعذر جلب فئات User Manager من MikroTik: $error';
        _selectedProfile = null;
      });
    } finally {
      MikrotikConnector.release(client);
    }
  }

  void _applyNormalizedOffset() {
    if (_imageKey.currentContext != null) {
      final RenderBox renderBox =
          _imageKey.currentContext!.findRenderObject() as RenderBox;
      final imageSize = renderBox.size;
      setState(() {
        _offset = Offset(
          _normalizedOffset.dx * imageSize.width,
          _normalizedOffset.dy * imageSize.height,
        );
        if (widget.existingTemplate != null) {
          _markerWidth =
              widget.existingTemplate!.markerWidthRatio * imageSize.width;
          _markerHeight =
              widget.existingTemplate!.markerHeightRatio * imageSize.height;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 6000,
        maxHeight: 6000,
        imageQuality: 95,
      );
      if (pickedFile == null || !mounted) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _offset = Offset.zero;
        _normalizedOffset = const Offset(0.5, 0.5);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _imageKey.currentContext == null) return;
        final renderObject = _imageKey.currentContext!.findRenderObject();
        if (renderObject is! RenderBox || !renderObject.hasSize) return;
        setState(() {
          _offset =
              Offset(renderObject.size.width / 2, renderObject.size.height / 2);
        });
      });
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context, 'تعذر اختيار صورة القالب: $error');
      }
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    final imageFile = _imageFile;
    final imageContext = _imageKey.currentContext;
    final selectedProfile = _selectedProfile?.trim() ?? '';
    final cardsPerPage = int.tryParse(_cardsPerPageController.text.trim());

    if (selectedProfile.isEmpty || !_routerProfiles.contains(selectedProfile)) {
      showErrorSnackBar(context, 'اختر فئة كروت جُلبت من MikroTik أولًا.');
      return;
    }
    if (imageFile == null || imageContext == null) {
      showErrorSnackBar(context, 'الرجاء اختيار صورة وانتظار تحميلها أولاً.');
      return;
    }
    if (cardsPerPage == null || cardsPerPage < 1 || cardsPerPage > 1000) {
      showErrorSnackBar(
          context, 'عدد الكروت في الصفحة يجب أن يكون بين 1 و1000.');
      return;
    }

    final renderObject = imageContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      showErrorSnackBar(context, 'لم يكتمل تحميل مساحة معاينة الصورة.');
      return;
    }
    final imageSizeOnScreen = renderObject.size;
    if (imageSizeOnScreen.width <= 0 || imageSizeOnScreen.height <= 0) {
      showErrorSnackBar(context, 'أبعاد معاينة الصورة غير صالحة.');
      return;
    }

    setState(() => _isLoading = true);
    _updateNormalizedOffset();

    try {
      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.isEmpty) {
        throw const FormatException('ملف الصورة فارغ.');
      }
      if (imageBytes.length > PdfTemplate.maxImageBytes) {
        throw const FormatException('حجم صورة القالب يتجاوز 12 ميجابايت.');
      }

      final decodedImage = await decodeImageFromList(imageBytes);
      final imageWidth = decodedImage.width.toDouble();
      final imageHeight = decodedImage.height.toDouble();
      if (imageWidth <= 0 ||
          imageHeight <= 0 ||
          imageWidth > PdfTemplate.maxImageDimension ||
          imageHeight > PdfTemplate.maxImageDimension) {
        throw const FormatException('أبعاد صورة القالب تتجاوز الحد المدعوم.');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final extension = p.extension(imageFile.path).toLowerCase();
      final safeExtension =
          extension == '.png' || extension == '.webp' ? extension : '.jpg';
      final fileName =
          'pdf_template_${DateTime.now().microsecondsSinceEpoch}$safeExtension';
      final savedImage = File(p.join(appDir.path, fileName));
      await savedImage.writeAsBytes(imageBytes, flush: true);

      final newTemplate = PdfTemplate(
        id: widget.existingTemplate?.id,
        profileName: selectedProfile,
        imagePath: savedImage.path,
        textXRatio: _normalizedOffset.dx,
        textYRatio: _normalizedOffset.dy,
        cardsPerPage: cardsPerPage,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        markerWidthRatio:
            (_markerWidth / imageSizeOnScreen.width).clamp(0.001, 1.0),
        markerHeightRatio:
            (_markerHeight / imageSizeOnScreen.height).clamp(0.001, 1.0),
      )..validate();

      await PdfTemplateStorage.save(newTemplate);

      final oldPath = widget.existingTemplate?.imagePath;
      if (oldPath != null && oldPath != newTemplate.imagePath) {
        final oldImage = File(oldPath);
        if (await oldImage.exists()) await oldImage.delete();
      }

      if (!mounted) return;
      showSuccessSnackBar(context, 'تم حفظ قالب فئة الكروت بنجاح.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context, 'فشل حفظ قالب PDF: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateNormalizedOffset() {
    if (_imageKey.currentContext != null) {
      final RenderBox renderBox =
          _imageKey.currentContext!.findRenderObject() as RenderBox;
      final imageSize = renderBox.size;

      final double dx = (_offset.dx / imageSize.width).clamp(0.0, 1.0);
      final double dy = (_offset.dy / imageSize.height).clamp(0.0, 1.0);

      setState(() {
        _normalizedOffset = Offset(dx, dy);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileNames = _routerProfiles;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_imageKey.currentContext != null && _offset == Offset.zero) {
        final RenderBox renderBox =
            _imageKey.currentContext!.findRenderObject() as RenderBox;
        setState(() {
          _offset = Offset(renderBox.size.width * _normalizedOffset.dx,
              renderBox.size.height * _normalizedOffset.dy);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existingTemplate == null ? 'إضافة قالب جديد' : 'تعديل قالب'),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري حفظ القالب...'),
              ],
            ))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (_isLoadingProfiles)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 10),
                                  Text('جاري جلب فئات الكروت من MikroTik...'),
                                ],
                              ),
                            )
                          else if (profileNames.isEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _profileLoadError ??
                                      'لم يُرجع User Manager أي فئة بروفايل.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _loadProfilesFromRouter,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(
                                      'إعادة جلب الفئات من MikroTik'),
                                ),
                              ],
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue:
                                  profileNames.contains(_selectedProfile)
                                      ? _selectedProfile
                                      : null,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              dropdownColor: Colors.white,
                              decoration: const InputDecoration(
                                labelText: 'فئة الكروت (Profile)',
                                helperText:
                                    'اختر فئة User Manager التي سيُستخدم لها القالب',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: profileNames
                                  .map(
                                    (name) => DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.black,
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
                                  value == null || value.trim().isEmpty
                                      ? 'الرجاء اختيار فئة الكروت'
                                      : null,
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cardsPerPageController,
                            decoration: const InputDecoration(
                                labelText: 'عدد الكروت في كل صفحة',
                                prefixIcon: Icon(Icons.view_module_outlined)),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الحقل مطلوب';
                              if (int.tryParse(v) == null ||
                                  int.parse(v) <= 0) {
                                return 'أدخل رقماً صحيحاً أكبر من صفر';
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
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('حرك المربع لتحديد منطقة طباعة الرقم',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onPanUpdate: (details) {
                              if (_imageKey.currentContext == null) return;
                              final RenderBox renderBox =
                                  _imageKey.currentContext!.findRenderObject()
                                      as RenderBox;
                              final newOffset = _offset + details.delta;

                              final constrainedDx =
                                  newOffset.dx.clamp(0.0, renderBox.size.width);
                              final constrainedDy = newOffset.dy
                                  .clamp(0.0, renderBox.size.height);

                              setState(() {
                                _offset = Offset(constrainedDx, constrainedDy);
                              });
                            },
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade700),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _imageFile == null
                                        ? const Center(
                                            child:
                                                Text('اختر صورة للقالب أولاً'))
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
                                                color: Colors.redAccent,
                                                width: 2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: Colors.redAccent
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
                              const Text('العرض:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Slider(
                                  value: _markerWidth,
                                  min: 20.0,
                                  max: 300.0,
                                  divisions: 28,
                                  label: _markerWidth.round().toString(),
                                  onChanged: (double value) {
                                    setState(() {
                                      _markerWidth = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('الارتفاع:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Slider(
                                  value: _markerHeight,
                                  min: 10.0,
                                  max: 150.0,
                                  divisions: 14,
                                  label: _markerHeight.round().toString(),
                                  onChanged: (double value) {
                                    setState(() {
                                      _markerHeight = value;
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
                                backgroundColor:
                                    Theme.of(context).primaryColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ||
                                    _isLoadingProfiles ||
                                    _routerProfiles.isEmpty
                                ? null
                                : _saveTemplate,
                            icon: const Icon(Icons.save),
                            label: const Text('حفظ القالب'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          )
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
