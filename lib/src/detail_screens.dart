import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'widgets.dart';

class _MedicationPharmacy {
  const _MedicationPharmacy({
    required this.name,
    required this.location,
    required this.distance,
    required this.price,
    required this.stockLabel,
    required this.stockLow,
  });

  final String name;
  final String location;
  final String distance;
  final int price;
  final String stockLabel;
  final bool stockLow;
}

class MedicationDetailScreen extends StatefulWidget {
  const MedicationDetailScreen({super.key});

  @override
  State<MedicationDetailScreen> createState() =>
      _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  static const _pharmacies = [
    _MedicationPharmacy(
      name: "Pharmacie de l'Estuaire",
      location: 'Libreville, Centre-ville',
      distance: '1.2 km',
      price: 2500,
      stockLabel: 'Stock: 50+',
      stockLow: false,
    ),
    _MedicationPharmacy(
      name: 'Pharmacie du Pont',
      location: 'Akanda',
      distance: '4.5 km',
      price: 2450,
      stockLabel: 'Stock limité (5)',
      stockLow: true,
    ),
    _MedicationPharmacy(
      name: "Pharmacie d'Owendo",
      location: 'Owendo',
      distance: '12 km',
      price: 2600,
      stockLabel: 'Stock: 24',
      stockLow: false,
    ),
  ];

  int _selectedPharmacy = 0;
  int _quantity = 1;
  bool _isFavorite = false;

  // Simulée comme dans le mockup Stitch : le panier de démonstration
  // contient déjà un article d'une autre pharmacie (voir CartScreen).
  final bool _cartHasOtherPharmacyItems = true;

  String _formatFcfa(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '$buffer FCFA';
  }

  Future<void> _handleAddToCart() async {
    if (_cartHasOtherPharmacyItems) {
      final emptyAndContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded,
              color: GabColors.danger),
          title: const Text("Panier d'une autre pharmacie"),
          content: const Text(
            'Votre panier contient déjà des articles de la Pharmacie du '
            'Centre. Un panier ne peut contenir que les produits d\'une '
            'seule pharmacie. Voulez-vous vider votre panier pour ajouter '
            'cet article ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vider le panier et continuer'),
            ),
          ],
        ),
      );
      if (emptyAndContinue != true || !mounted) return;
    }
    if (!mounted) return;
    final pharmacy = _pharmacies[_selectedPharmacy];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$_quantity × Doliprane 1000mg ajouté au panier (${pharmacy.name}, démo).'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GabColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back,
                        color: GabColors.primary),
                  ),
                  const Text(
                    'Détails',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GabColors.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        setState(() => _isFavorite = !_isFavorite),
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite
                          ? GabColors.danger
                          : GabColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                      content: Text('Partage indisponible en démonstration.'),
                    )),
                    icon: const Icon(Icons.share_outlined,
                        color: GabColors.primary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: GabColors.outlineVariant),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(32)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: GabColors.softGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.medication_outlined,
                                  size: 72, color: GabColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Text(
                                'Doliprane 1000mg',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: GabColors.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA8F4B9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'En Stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF287243),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Paracétamol',
                            style: TextStyle(
                                fontSize: 18, color: GabColors.muted)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: const [
                            _InfoTag('Comprimé sécable'),
                            _InfoTag('Boîte de 8'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Pharmacies Disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: GabColors.primary,
                                ),
                              ),
                            ),
                            Text('${_pharmacies.length} trouvées',
                                style:
                                    const TextStyle(color: GabColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < _pharmacies.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PharmacyOptionCard(
                              pharmacy: _pharmacies[i],
                              selected: i == _selectedPharmacy,
                              formatFcfa: _formatFcfa,
                              onTap: () =>
                                  setState(() => _selectedPharmacy = i),
                              onOpenDetail: () =>
                                  Navigator.pushNamed(context, '/pharmacy'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: GabColors.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: GabColors.softGreen,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              icon: const Icon(Icons.remove),
                              color: GabColors.primary,
                              constraints: const BoxConstraints(
                                  minWidth: 44, minHeight: 44),
                            ),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '$_quantity',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: GabColors.primary,
                                    fontSize: 16),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _quantity++),
                              icon: const Icon(Icons.add),
                              color: GabColors.primary,
                              constraints: const BoxConstraints(
                                  minWidth: 44, minHeight: 44),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _handleAddToCart,
                            icon: const Icon(Icons.shopping_cart_outlined),
                            label: const Text('Ajouter au panier'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: GabColors.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(
                color: GabColors.muted, fontWeight: FontWeight.w600)),
      );
}

class _PharmacyOptionCard extends StatelessWidget {
  const _PharmacyOptionCard({
    required this.pharmacy,
    required this.selected,
    required this.formatFcfa,
    required this.onTap,
    required this.onOpenDetail,
  });

  final _MedicationPharmacy pharmacy;
  final bool selected;
  final String Function(int) formatFcfa;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? Colors.white : GabColors.softGreen,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onOpenDetail,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? GabColors.primary : GabColors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pharmacy.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: GabColors.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${pharmacy.location} • ${pharmacy.distance}',
                              style:
                                  const TextStyle(color: GabColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          formatFcfa(pharmacy.price),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: GabColors.primary,
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle,
                              color: GabColors.primary, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pharmacy.stockLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: pharmacy.stockLow
                            ? GabColors.danger
                            : GabColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

class _PharmacyProduct {
  const _PharmacyProduct({
    required this.category,
    required this.name,
    required this.details,
    required this.price,
  });

  final String category;
  final String name;
  final String details;
  final int price;
}

class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({super.key});

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  bool _isFavorite = false;

  static const _products = [
    _PharmacyProduct(
      category: 'Médicament',
      name: 'Doliprane 1000mg',
      details: 'Boîte de 8 gélules',
      price: 1250,
    ),
    _PharmacyProduct(
      category: 'Vitamines',
      name: 'Alvityl Vitalité',
      details: 'Sirop 150ml',
      price: 4800,
    ),
    _PharmacyProduct(
      category: 'Hygiène',
      name: 'Biseptine Spray',
      details: 'Spray 100ml',
      price: 3100,
    ),
  ];

  String _formatFcfa(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '$buffer FCFA';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: GabColors.primary),
                    ),
                    const Text(
                      "Gab'Pharma",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text('Partage indisponible en démonstration.'),
                      )),
                      icon: const Icon(Icons.share_outlined,
                          color: GabColors.primary),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _isFavorite = !_isFavorite),
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite
                            ? GabColors.danger
                            : GabColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GabColors.outlineVariant),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 176,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0B7A3E),
                                Color(0xFF39B27A),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.storefront,
                                color: Colors.white, size: 56),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: GabColors.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'PHARMACIE DE GARDE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Pharmacie de la Garde',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: GabColors.softGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const _InfoRow(
                                  icon: Icons.location_on_outlined,
                                  title: 'Adresse',
                                  value:
                                      'Boulevard Triomphal, Face au Sénat, Libreville, Gabon',
                                ),
                                const SizedBox(height: 14),
                                const _InfoRow(
                                  icon: Icons.call_outlined,
                                  title: 'Contact',
                                  value: '+241 01 76 54 32',
                                ),
                                const SizedBox(height: 14),
                                _InfoRow(
                                  icon: Icons.schedule_outlined,
                                  title: 'Horaires',
                                  value:
                                      'Ouvert tous les jours, dimanches et jours fériés inclus.',
                                  trailing: const Text(
                                    'Ouvert 24h/24',
                                    style: TextStyle(
                                      color: GabColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Container(
                                  height: 140,
                                  width: double.infinity,
                                  color: const Color(0xFFDCECE3),
                                  child: const Center(
                                    child: Icon(Icons.map_outlined,
                                        size: 40, color: GabColors.muted),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      onPressed: () =>
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Navigation indisponible en démonstration.'),
                                      )),
                                      icon: const Icon(Icons.directions,
                                          color: GabColors.primary),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: GabColors.outlineVariant),
                                    ),
                                    child: const Text(
                                      '850m de votre position',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: GabColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Services & Assurances',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: GabColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _ServiceChip(
                                icon: Icons.local_shipping_outlined,
                                label: 'Zones: Libreville, Akanda, Owendo',
                              ),
                              _ServiceChip(
                                icon: Icons.payments_outlined,
                                label: 'Paiement à la livraison',
                              ),
                              _ServiceChip(
                                icon: Icons.verified_outlined,
                                label: 'CNAMGS Acceptée',
                                accent: true,
                              ),
                              _ServiceChip(
                                icon: Icons.verified_outlined,
                                label: 'AXA Gabon',
                                accent: true,
                              ),
                              _ServiceChip(
                                icon: Icons.verified_outlined,
                                label: 'ASCOMA',
                                accent: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Produits disponibles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: GabColors.primary,
                                  ),
                                ),
                                Text('Parcourir le stock de cette pharmacie',
                                    style:
                                        TextStyle(color: GabColors.muted)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, '/home', (route) => false),
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 228,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          for (final product in _products)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _PharmacyProductCard(
                                product: product,
                                formatFcfa: _formatFcfa,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                  context, '/home', (route) => false),
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text('Commander dans cette pharmacie'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    'Appel vers +241 01 76 54 32 — composition indisponible en démonstration.'),
                              )),
                              style: FilledButton.styleFrom(
                                backgroundColor: GabColors.softGreen,
                                foregroundColor: GabColors.primary,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.call_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Appeler la pharmacie'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFA8F4B9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00210D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: GabColors.primary)),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: GabColors.muted)),
              ],
            ),
          ),
        ],
      );
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accent
              ? const Color(0xFFA8F4B9).withValues(alpha: 0.5)
              : GabColors.softGreen,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: accent
                  ? GabColors.secondary.withValues(alpha: 0.3)
                  : GabColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: GabColors.secondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PharmacyProductCard extends StatelessWidget {
  const _PharmacyProductCard({
    required this.product,
    required this.formatFcfa,
  });

  final _PharmacyProduct product;
  final String Function(int) formatFcfa;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, '/medication'),
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GabColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 96,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: GabColors.softGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.medication_outlined,
                        color: GabColors.primary, size: 32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: GabColors.muted,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: GabColors.primary),
                ),
                Text(
                  product.details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: GabColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatFcfa(product.price),
                      style: const TextStyle(
                        color: GabColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${product.name} ajouté au panier (démo).'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: GabColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_shopping_cart,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
