import 'package:flutter/material.dart';

import 'auth_screens.dart';
import 'core/theme.dart';
import 'detail_screens.dart';
import 'patient_shell.dart';

class GabPharmaPatientApp extends StatelessWidget {
  const GabPharmaPatientApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
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
          '/insurance': (_) => const SimpleFeatureScreen(
                title: 'Mon assurance',
                icon: Icons.health_and_safety_outlined,
                description:
                    'Affiliation et estimation informative de couverture, sans promesse de droits.',
              ),
          '/notifications': (_) => const SimpleFeatureScreen(
                title: 'Notifications',
                icon: Icons.notifications_outlined,
                description:
                    'Transitions de commandes, échéances et événements de livraison.',
              ),
          '/support': (_) => const SimpleFeatureScreen(
                title: 'Centre d’aide et tickets',
                icon: Icons.support_agent,
                description:
                    'Créez une demande liée à une commande et suivez les réponses du Staff.',
                actionLabel: 'Ouvrir une conversation',
                nextRoute: '/support-thread',
              ),
          '/support-thread': (_) => const SimpleFeatureScreen(
                title: 'Conversation Support',
                icon: Icons.forum_outlined,
                description:
                    'Messages visibles du patient et pièces jointes protégées.',
              ),
          '/security': (_) => const SimpleFeatureScreen(
                title: 'Sécurité et paramètres',
                icon: Icons.security_outlined,
                description:
                    'Mot de passe, session, confidentialité et préférences. La 2FA reste obligatoire.',
              ),
        },
      );
}
