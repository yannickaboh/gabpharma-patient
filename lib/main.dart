import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initialize();
  runApp(const GabPharmaPatientApp());
}
