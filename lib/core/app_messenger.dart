import 'package:flutter/material.dart';

/// Application-level messenger used by background services that have no
/// widget [BuildContext]. UI features should prefer their local messenger.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
