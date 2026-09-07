import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/app_config.dart';
import 'src/core/push_notification_service.dart';
import 'src/detail_screens.dart'
    show ConversationScreen, DeliveryTrackingScreen, OrderDetailScreen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PushNotificationService.onNotificationTap = _handlePushNotificationTap;
  await PushNotificationService.initialize();
  runApp(const GabPharmaPatientApp());
}

// Champs envoyés par `send_push_to_user` côté Django (voir
// apps/notifications/push.py et ses appelants orders/support/deliveries) :
// toujours un `type`, plus un id spécifique au type. "order", "support_ticket"
// et "delivery" ont chacun un écran patient réellement branché sur un id réel
// ("delivery" pousse vers le suivi de livraison via `order_id`, voir
// CLAUDE.md, écran 17).
void _handlePushNotificationTap(Map<String, dynamic> data) {
  final navigator = AppConfig.navigatorKey.currentState;
  if (navigator == null) return;
  switch (data['type']) {
    case 'order':
      final orderId = int.tryParse(data['order_id']?.toString() ?? '');
      if (orderId != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
        );
      }
    case 'support_ticket':
      final ticketId = int.tryParse(data['ticket_id']?.toString() ?? '');
      if (ticketId != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ConversationScreen(ticketId: ticketId),
          ),
        );
      }
    case 'delivery':
      final orderId = int.tryParse(data['order_id']?.toString() ?? '');
      if (orderId != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => DeliveryTrackingScreen(orderId: orderId),
          ),
        );
      }
  }
}
