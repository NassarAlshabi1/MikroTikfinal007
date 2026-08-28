class PdfTemplate {
  static const int currentSchemaVersion = 2;
  static const int maxImageBytes = 12 * 1024 * 1024;
  static const int maxImageDimension = 6000;

  final String id;
  final String profileName;
  final String imagePath;
  final double textXRatio;
  final double textYRatio;
  final int cardsPerPage;
  final double imageWidth;
  final double imageHeight;
  final double markerWidthRatio;
  final double markerHeightRatio;
  final int schemaVersion;

  PdfTemplate({
    String? id,
    required this.profileName,
    required this.imagePath,
    required this.textXRatio,
    required this.textYRatio,
    required this.cardsPerPage,
    required this.imageWidth,
    required this.imageHeight,
    required this.markerWidthRatio,
    required this.markerHeightRatio,
    this.schemaVersion = currentSchemaVersion,
  }) : id = id ?? _createId(profileName, imagePath);

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'id': id,
        'profileName': profileName,
        'imagePath': imagePath,
        'textXRatio': textXRatio,
        'textYRatio': textYRatio,
        'cardsPerPage': cardsPerPage,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'markerWidthRatio': markerWidthRatio,
        'markerHeightRatio': markerHeightRatio,
      };

  factory PdfTemplate.fromJson(Map<String, dynamic> json) {
    final profileName = _requiredString(json, 'profileName');
    final imagePath = _requiredString(json, 'imagePath');
    final template = PdfTemplate(
      id: _optionalString(json['id']) ?? _createId(profileName, imagePath),
      profileName: profileName,
      imagePath: imagePath,
      textXRatio: _doubleValue(json['textXRatio'], fallback: 0.5),
      textYRatio: _doubleValue(json['textYRatio'], fallback: 0.5),
      cardsPerPage: _intValue(json['cardsPerPage'], fallback: 1),
      imageWidth: _doubleValue(json['imageWidth'], fallback: 1),
      imageHeight: _doubleValue(json['imageHeight'], fallback: 1),
      markerWidthRatio: _doubleValue(json['markerWidthRatio'], fallback: 0.3),
      markerHeightRatio: _doubleValue(json['markerHeightRatio'], fallback: 0.1),
      schemaVersion: _intValue(
        json['schemaVersion'],
        fallback: 1,
      ),
    );
    template.validate();
    return template;
  }

  PdfTemplate copyWith({
    String? id,
    String? profileName,
    String? imagePath,
    double? textXRatio,
    double? textYRatio,
    int? cardsPerPage,
    double? imageWidth,
    double? imageHeight,
    double? markerWidthRatio,
    double? markerHeightRatio,
  }) {
    return PdfTemplate(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      imagePath: imagePath ?? this.imagePath,
      textXRatio: textXRatio ?? this.textXRatio,
      textYRatio: textYRatio ?? this.textYRatio,
      cardsPerPage: cardsPerPage ?? this.cardsPerPage,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      markerWidthRatio: markerWidthRatio ?? this.markerWidthRatio,
      markerHeightRatio: markerHeightRatio ?? this.markerHeightRatio,
    );
  }

  void validate() {
    if (profileName.trim().isEmpty || profileName.length > 128) {
      throw const FormatException('اسم بروفايل قالب PDF غير صالح.');
    }
    if (imagePath.trim().isEmpty) {
      throw const FormatException('مسار صورة قالب PDF فارغ.');
    }
    if (cardsPerPage < 1 || cardsPerPage > 1000) {
      throw const FormatException(
          'عدد الكروت في الصفحة يجب أن يكون بين 1 و1000.');
    }
    if (!imageWidth.isFinite ||
        !imageHeight.isFinite ||
        imageWidth <= 0 ||
        imageHeight <= 0) {
      throw const FormatException('أبعاد صورة قالب PDF غير صالحة.');
    }
    _validateRatio(textXRatio, 'موضع النص الأفقي');
    _validateRatio(textYRatio, 'موضع النص العمودي');
    if (!markerWidthRatio.isFinite ||
        markerWidthRatio <= 0 ||
        markerWidthRatio > 1) {
      throw const FormatException('عرض منطقة النص يجب أن يكون بين 0 و1.');
    }
    if (!markerHeightRatio.isFinite ||
        markerHeightRatio <= 0 ||
        markerHeightRatio > 1) {
      throw const FormatException('ارتفاع منطقة النص يجب أن يكون بين 0 و1.');
    }
  }

  static void _validateRatio(double value, String label) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw FormatException('$label يجب أن يكون بين 0 و1.');
    }
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isEmpty) throw FormatException('الحقل $key مفقود في قالب PDF.');
    return value;
  }

  static String? _optionalString(Object? value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static double _doubleValue(Object? value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _intValue(Object? value, {required int fallback}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _createId(String profileName, String imagePath) {
    return 'pdf-${profileName.hashCode.abs()}-${imagePath.hashCode.abs()}';
  }
}
