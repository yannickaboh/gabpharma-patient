import 'package:flutter/widgets.dart';

abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8004/api/v1/',
  );

  static const demoMode =
      bool.fromEnvironment('DEMO_MODE', defaultValue: false);

  static final navigatorKey = GlobalKey<NavigatorState>();
}
