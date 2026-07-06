import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'widgets.dart';

class MedicationDetailScreen extends StatelessWidget {
  const MedicationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Détail médicament'),
          actions: [
            IconButton(
                onPressed: () {}, icon: const Icon(Icons.favorite_border)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: GabColors.softGreen,
                child: Icon(
                  Icons.medication_outlined,
                  size: 52,
                  color: GabColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Paracétamol',
                style: Theme.of(context).textTheme.headlineMedium),
            const Text('DCI : Paracétamol · 500 mg · Comprimé'),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusPill('OTC disponible'),
            ),
            const SectionTitle('Disponible dans 3 pharmacies'),
            Card(
              child: ListTile(
                onTap: () => Navigator.pushNamed(context, '/pharmacy'),
                title: const Text('Pharmacie du Centre'),
                subtitle: const Text('Libreville · 18 unités'),
                trailing: const Text(
                  '1 500 FCFA',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Ajouté au panier de démonstration')),
              ),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Ajouter au panier'),
            ),
          ],
        ),
      );
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Finaliser la commande')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Adresse de remise',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 14),
            const DropdownMenu(
              expandedInsets: EdgeInsets.zero,
              initialSelection: 'delivery',
              label: Text('Mode de réception'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'delivery', label: 'Livraison'),
                DropdownMenuEntry(
                    value: 'pickup', label: 'Retrait en pharmacie'),
              ],
            ),
            const SectionTitle('Paiement'),
            Card(
              child: RadioGroup<bool>(
                groupValue: true,
                onChanged: (_) {},
                child: const Column(
                  children: [
                    RadioListTile(
                      value: true,
                      title: Text('Espèces à la livraison'),
                    ),
                    RadioListTile(
                      value: false,
                      title: Text('Mobile Money (simulation)'),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Total'),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'À payer',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '8 200 FCFA',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/confirmation'),
              child: const Text('Confirmer la commande'),
            ),
          ],
        ),
      );
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Commande #GP-1042')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill('En préparation'),
                    SizedBox(height: 12),
                    Text(
                      'Pharmacie du Centre',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text('Livraison · Paiement en espèces'),
                  ],
                ),
              ),
            ),
            const SectionTitle('Articles'),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Paracétamol 500 mg'),
                    trailing: Text('3 000 FCFA'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text('Vitamine C 1000 mg'),
                    trailing: Text('3 200 FCFA'),
                  ),
                ],
              ),
            ),
            const SectionTitle('Progression'),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          Icon(Icons.check_circle, color: GabColors.primary),
                      title: Text('Commande créée'),
                      subtitle: Text('06/07/2026 à 09:14'),
                    ),
                    ListTile(
                      leading: Icon(Icons.pending, color: Colors.orange),
                      title: Text('Préparation par la pharmacie'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () => Navigator.pushNamed(context, '/delivery'),
              child: const Text('Suivre la livraison'),
            ),
          ],
        ),
      );
}

class SimpleFeatureScreen extends StatelessWidget {
  const SimpleFeatureScreen({
    required this.title,
    required this.icon,
    required this.description,
    super.key,
    this.actionLabel,
    this.nextRoute,
  });
  final String title;
  final IconData icon;
  final String description;
  final String? actionLabel;
  final String? nextRoute;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(icon, color: GabColors.primary, size: 52),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(description, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Données de démonstration'),
                subtitle: Text(
                  'Cet écran sera alimenté par l’API mobile Django. Aucune règle métier n’est calculée localement.',
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: nextRoute == null
                    ? () {}
                    : () => Navigator.pushNamed(context, nextRoute!),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      );
}
