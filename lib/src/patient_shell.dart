import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'widgets.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;

  static const _screens = [
    PatientHomeScreen(),
    SearchScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            const DemoBanner(),
            Expanded(
              child: IndexedStack(index: _index, children: _screens),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Accueil',
            ),
            NavigationDestination(icon: Icon(Icons.search), label: 'Recherche'),
            NavigationDestination(
              icon: Badge(
                label: Text('2'),
                child: Icon(Icons.shopping_bag_outlined),
              ),
              label: 'Panier',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Commandes',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
        ),
      );
}

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, Grâce',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      Text('Que recherchez-vous aujourd’hui ?'),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                  icon: const Badge(child: Icon(Icons.notifications_outlined)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              readOnly: true,
              onTap: () {},
              decoration: const InputDecoration(
                hintText: 'Nom du médicament ou DCI',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SectionTitle('Commande en cours'),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pushNamed(context, '/order-detail'),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Commande #GP-1042',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          StatusPill('En préparation'),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text('Pharmacie du Centre · Retrait'),
                      SizedBox(height: 6),
                      Text(
                        '12 500 FCFA',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SectionTitle('Accès rapide'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _Shortcut('Favoris', Icons.favorite_outline, '/favorites'),
                _Shortcut(
                  'Mon assurance',
                  Icons.health_and_safety_outlined,
                  '/insurance',
                ),
                _Shortcut('Paiements', Icons.payments_outlined, '/payments'),
                _Shortcut('Aide & support', Icons.support_agent, '/support'),
              ],
            ),
          ],
        ),
      );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: GabColors.primary),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Rechercher',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Paracétamol, vitamine C…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text('Libreville'),
                  selected: true,
                  onSelected: null,
                ),
                FilterChip(
                  label: Text('Disponible'),
                  selected: true,
                  onSelected: null,
                ),
                FilterChip(
                    label: Text('Prix'), selected: false, onSelected: null),
              ],
            ),
            const SectionTitle('8 résultats'),
            for (final item in const [
              ('Paracétamol', '500 mg · Comprimé', '1 500 FCFA'),
              ('Vitamine C', '1000 mg · Effervescent', '3 200 FCFA'),
              ('Sérum physiologique', 'Unidose', '2 000 FCFA'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(context, '/medication'),
                    leading: const CircleAvatar(
                      backgroundColor: GabColors.softGreen,
                      child: Icon(
                        Icons.medication_outlined,
                        color: GabColors.primary,
                      ),
                    ),
                    title: Text(
                      item.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${item.$2}\nPharmacie du Centre'),
                    isThreeLine: true,
                    trailing: Text(
                      item.$3,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Mon panier',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('Pharmacie du Centre · panier mono-pharmacie'),
            const SectionTitle('2 articles'),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Paracétamol 500 mg'),
                    subtitle: Text('2 × 1 500 FCFA'),
                    trailing: Text('−  2  +'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text('Vitamine C 1000 mg'),
                    subtitle: Text('1 × 3 200 FCFA'),
                    trailing: Text('−  1  +'),
                  ),
                ],
              ),
            ),
            const SectionTitle('Récapitulatif'),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Sous-total')),
                        Text('6 200 FCFA'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text('Livraison')),
                        Text('À calculer'),
                      ],
                    ),
                    Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '6 200 FCFA',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              child: const Text('Passer la commande'),
            ),
          ],
        ),
      );
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Mes commandes',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('Toutes')),
                Chip(label: Text('En cours')),
                Chip(label: Text('Terminées')),
              ],
            ),
            const SizedBox(height: 16),
            for (final order in const [
              ('GP-1042', 'En préparation', '12 500 FCFA'),
              ('GP-1038', 'Livrée', '8 300 FCFA'),
              ('GP-1021', 'Retirée', '4 750 FCFA'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(context, '/order-detail'),
                    title: Text(
                      'Commande #${order.$1}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('Pharmacie du Centre · ${order.$3}'),
                    trailing: StatusPill(order.$2),
                  ),
                ),
              ),
          ],
        ),
      );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Mon profil',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: GabColors.primary,
                      child: Text('GN', style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grâce Nziengui',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text('patient.demo@gabpharma.ga'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final item in const [
              ('Mon assurance', Icons.health_and_safety_outlined, '/insurance'),
              (
                'Paiements et remboursements',
                Icons.payments_outlined,
                '/payments'
              ),
              ('Notifications', Icons.notifications_outlined, '/notifications'),
              ('Aide et tickets', Icons.support_agent, '/support'),
              ('Sécurité et paramètres', Icons.security_outlined, '/security'),
            ])
              Card(
                child: ListTile(
                  onTap: () => Navigator.pushNamed(context, item.$3),
                  leading: Icon(item.$2),
                  title: Text(item.$1),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ],
        ),
      );
}
