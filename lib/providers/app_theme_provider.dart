import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';

final appThemeProvider = ChangeNotifierProvider<AppTheme>(
  (ref) => AppTheme()..initialize(),
);
