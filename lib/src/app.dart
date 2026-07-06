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
          '/register': (_) => const SimpleFeatureScreen(
                title: 'Inscription Patient',
                icon: Icons.person_add_alt_1,
                description:
                    'Création sécurisée du compte Patient et recueil des consentements.',
              ),
          '/password-reset': (_) => const SimpleFeatureScreen(
                title: 'Mot de passe oublié',
                icon: Icons.password,
                description:
                    'Identification, code de vérification puis définition d’un nouveau mot de passe.',
              ),
          '/medication': (_) => const MedicationDetailScreen(),
          '/pharmacy': (_) => const SimpleFeatureScreen(
                title: 'Pharmacie du Centre',
                icon: Icons.local_pharmacy_outlined,
                description:
                    'Libreville · horaires, zones desservies, paiements et plans acceptés.',
              ),
          '/favorites': (_) => const SimpleFeatureScreen(
                title: 'Mes favoris',
                icon: Icons.favorite_outline,
                description:
                    'Vos médicaments favoris avec une disponibilité recalculée par le serveur.',
              ),
          '/checkout': (_) => const CheckoutScreen(),
          '/payment': (_) => const SimpleFeatureScreen(
                title: 'Paiement',
                icon: Icons.payments_outlined,
                description:
                    'Espèces, Airtel Money, Moov Money ou Visa selon les moyens actifs.',
              ),
          '/confirmation': (_) => const SimpleFeatureScreen(
                title: 'Commande enregistrée',
                icon: Icons.task_alt,
                description:
                    'La demande a été transmise à la pharmacie. Elle n’est pas encore acceptée.',
                actionLabel: 'Voir la commande',
                nextRoute: '/order-detail',
              ),
          '/order-detail': (_) => const OrderDetailScreen(),
          '/delivery': (_) => const SimpleFeatureScreen(
                title: 'Suivi de livraison',
                icon: Icons.delivery_dining,
                description:
                    'Chronologie de la course. Le code de remise reste transmis par le canal sécurisé.',
              ),
          '/payments': (_) => const SimpleFeatureScreen(
                title: 'Paiements et remboursements',
                icon: Icons.account_balance_wallet_outlined,
                description:
                    'Historique financier séparé du statut opérationnel des commandes.',
              ),
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
