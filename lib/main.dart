import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/app_bootstrap.dart';

/// Compatibility exports for integrations and older screens. New code should
/// depend on the owning feature/core library directly, not this entrypoint.
export 'app.dart' show ApplicationRoot, MyApp;
export 'core/app_runtime.dart' show appDatabaseProvider, scaffoldMessengerKey;
export 'core/navigation/custom_page_route.dart' show CustomPageRoute;
export 'core/widgets/custom_loading_indicator.dart'
    show CustomLoadingIndicator;
export 'features/auth/presentation/login_screen.dart' show LoginScreen;
export 'features/dashboard/presentation/home_screen.dart'
    show HomeScreen, MikrotikMode, ServiceItem;
export 'snackbar_helpers.dart' show showErrorSnackBar, showSuccessSnackBar;

Future<void> main() async {
  await bootstrapApplication();
  runApp(const ApplicationRoot());
}
