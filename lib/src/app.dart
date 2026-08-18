import 'package:flutter/material.dart';

import 'auth_screens.dart';
import 'core/app_config.dart';
import 'core/theme.dart';
import 'detail_screens.dart';
import 'patient_shell.dart';

class GabPharmaPatientApp extends StatelessWidget {
  const GabPharmaPatientApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: AppConfig.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: "Gab'Pharma Patient",
        theme: buildPatientTheme(),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/verify': (_) => const VerifyScreen(),
          '/home': (_) => const PatientShell(),
          '/register': (_) => const RegisterScreen(),
          '/password-reset': (_) => const PasswordResetScreen(),
          '/medication': (_) => const MedicationDetailScreen(),
          '/pharmacy': (_) => const PharmacyDetailScreen(),
          '/favorites': (_) => const FavoritesScreen(),
          '/checkout': (_) => const CheckoutScreen(),
          '/payment': (_) => const PaymentScreen(
                orderNumber: 'GP-1051',
                itemsTotal: 8800,
                deliveryFee: 1500,
                discount: 1210,
              ),
          '/confirmation': (_) => const OrderConfirmationScreen(),
          '/order-detail': (_) => const OrderDetailScreen(),
          '/delivery': (_) => const DeliveryTrackingScreen(),
          '/payments': (_) => const PaymentsHistoryScreen(),
          '/insurance': (_) => const InsuranceScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/support': (_) => const HelpCenterScreen(),
          '/support-thread': (_) => const ConversationScreen(),
          '/security': (_) => const SecurityScreen(),
        },
      );
}
