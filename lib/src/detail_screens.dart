import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';

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

enum _DeliveryMethod { home, pickup }

enum _PaymentMethod { mobileMoney, cash }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _cartItems = [
    ('Doliprane 1000mg', 2, 2500),
    ('Biseptine Spray', 1, 3800),
  ];
  static const _insuranceReduction = 1210;

  String _commune = 'Libreville';
  _DeliveryMethod _deliveryMethod = _DeliveryMethod.home;
  _PaymentMethod _paymentMethod = _PaymentMethod.mobileMoney;
  final _addressDetails = TextEditingController();

  @override
  void dispose() {
    _addressDetails.dispose();
    super.dispose();
  }

  int get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.$2 * item.$3);

  int get _deliveryFee => _deliveryMethod == _DeliveryMethod.home ? 1500 : 0;

  int get _total => _subtotal + _deliveryFee - _insuranceReduction;

  String _formatFcfa(int amount) {
    final negative = amount < 0;
    final s = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '${negative ? '- ' : ''}$buffer FCFA';
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
                      'Caisse',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary,
                      ),
                    ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Text(
                        "Gab'Pharma",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GabColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GabColors.outlineVariant),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StepDot(number: '1', label: 'Livraison', active: true),
                        Container(
                            width: 32, height: 2, color: GabColors.outlineVariant),
                        const _StepDot(
                            number: '2', label: 'Paiement', active: false),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _CheckoutCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'Adresse de livraison',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (final commune in const [
                                'Libreville',
                                'Akanda',
                                'Owendo'
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _SelectableChip(
                                      label: commune,
                                      selected: _commune == commune,
                                      onTap: () =>
                                          setState(() => _commune = commune),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Précisions sur l'adresse (Quartier, Immeuble, Repères)",
                            style: TextStyle(
                                fontSize: 12, color: GabColors.muted),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressDetails,
                            decoration: const InputDecoration(
                              hintText:
                                  'Ex: Face à la pharmacie de la cité, immeuble vert',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CheckoutCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Méthode de réception',
                      child: Column(
                        children: [
                          _OptionCard(
                            icon: Icons.home_outlined,
                            title: 'Livraison à domicile',
                            subtitle: 'Sous 2 à 4 heures',
                            trailing: '1 500 FCFA',
                            selected:
                                _deliveryMethod == _DeliveryMethod.home,
                            onTap: () => setState(
                                () => _deliveryMethod = _DeliveryMethod.home),
                          ),
                          const SizedBox(height: 10),
                          _OptionCard(
                            icon: Icons.storefront_outlined,
                            title: 'Retrait en pharmacie',
                            subtitle: 'Prêt en 30 minutes',
                            trailing: 'Gratuit',
                            selected:
                                _deliveryMethod == _DeliveryMethod.pickup,
                            onTap: () => setState(() =>
                                _deliveryMethod = _DeliveryMethod.pickup),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GabColors.softGreen,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: GabColors.primary.withValues(alpha: 0.3),
                            style: BorderStyle.solid),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: GabColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Affiliation Assurance (CNAMGS)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: GabColors.primary),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Cette commande sera traitée avec votre affiliation enregistrée. Veuillez présenter votre carte lors de la réception : le tiers-payant final reste validé par la pharmacie.',
                                  style: TextStyle(color: GabColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CheckoutCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Mode de paiement',
                      child: Column(
                        children: [
                          _OptionCard(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Text('M',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ),
                            title: 'Airtel Money / Moov',
                            selected:
                                _paymentMethod == _PaymentMethod.mobileMoney,
                            onTap: () => setState(() => _paymentMethod =
                                _PaymentMethod.mobileMoney),
                          ),
                          const SizedBox(height: 10),
                          _OptionCard(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: GabColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.payments_outlined,
                                  color: Colors.white, size: 18),
                            ),
                            title: 'Espèces à la livraison',
                            selected: _paymentMethod == _PaymentMethod.cash,
                            onTap: () => setState(
                                () => _paymentMethod = _PaymentMethod.cash),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GabColors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Récapitulatif',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          for (final item in _cartItems)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: GabColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${item.$2}x',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(item.$1)),
                                  Text(_formatFcfa(item.$2 * item.$3),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                                height: 1, color: GabColors.outlineVariant),
                          ),
                          _SummaryLine('Sous-total', _formatFcfa(_subtotal)),
                          const SizedBox(height: 6),
                          _SummaryLine('Frais de livraison',
                              _formatFcfa(_deliveryFee)),
                          const SizedBox(height: 6),
                          _SummaryLine(
                            'Réduction (estimation CNAMGS)',
                            _formatFcfa(-_insuranceReduction),
                            valueColor: GabColors.primary,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                                height: 1, color: GabColors.outlineVariant),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Expanded(
                                child: Text('Total à payer',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatFcfa(_total),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: GabColors.primary),
                                  ),
                                  const Text('TVA INCLUSE',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: GabColors.muted,
                                          letterSpacing: 0.5)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              orderNumber: 'GP-1051',
                              itemsTotal: _subtotal,
                              deliveryFee: _deliveryFee,
                              discount: _insuranceReduction,
                              deliveryLabel: _deliveryMethod ==
                                      _DeliveryMethod.home
                                  ? 'Livraison à domicile'
                                  : 'Retrait en pharmacie',
                              deliverySubtitle: _deliveryMethod ==
                                      _DeliveryMethod.home
                                  ? 'Sous 2 à 4 heures · À domicile'
                                  : 'Prêt en 30 minutes',
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Confirmer ma commande'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14, color: GabColors.muted),
                        SizedBox(width: 6),
                        Text('Paiement 100% sécurisé',
                            style:
                                TextStyle(color: GabColors.muted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _StepDot extends StatelessWidget {
  const _StepDot(
      {required this.number, required this.label, required this.active});

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? GabColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: active
                  ? null
                  : Border.all(color: GabColors.outlineVariant, width: 2),
            ),
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : GabColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? GabColors.primary : GabColors.muted,
            ),
          ),
          const SizedBox(width: 8),
        ],
      );
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GabColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: GabColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? GabColors.softGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? GabColors.primary : GabColors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? GabColors.primary : GabColors.ink,
              ),
            ),
          ),
        ),
      );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.subtitle,
    this.trailing,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? GabColors.softGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? GabColors.primary : GabColors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (leading != null)
                  leading!
                else if (icon != null)
                  Icon(icon, color: GabColors.ink),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                color: GabColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(trailing!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: GabColors.primary)),
              ],
            ),
          ),
        ),
      );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: GabColors.muted))),
          Text(value,
              style: TextStyle(
                color: valueColor ?? GabColors.muted,
                fontWeight: valueColor != null
                    ? FontWeight.w700
                    : FontWeight.w400,
              )),
        ],
      );
}

enum _PayMethod { airtel, moov, visa, cash }

enum _PaySimState { none, pending, success, error }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    required this.orderNumber,
    required this.itemsTotal,
    required this.deliveryFee,
    this.discount = 0,
    this.pharmacyName = 'Pharmacie Akanda',
    this.deliveryLabel = 'Livraison à domicile',
    this.deliverySubtitle = 'Sous 2 à 4 heures · À domicile',
    super.key,
  });

  final String orderNumber;
  final int itemsTotal;
  final int deliveryFee;
  final int discount;
  final String pharmacyName;
  final String deliveryLabel;
  final String deliverySubtitle;

  int get total => itemsTotal + deliveryFee - discount;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayMethod? _method;
  _PaySimState _simState = _PaySimState.none;
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvcController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    super.dispose();
  }

  String _formatFcfa(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '$buffer FCFA';
  }

  Future<void> _confirmAndPay() async {
    if (_method == null) return;
    setState(() => _simState = _PaySimState.pending);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // Démonstration : issue aléatoire (succès ~70%) pour illustrer les deux
    // états, comme dans le prototype Stitch — aucune vraie transaction n'a
    // lieu, il n'y a pas de passerelle de paiement branchée.
    final success = Random().nextDouble() > 0.3;
    setState(() => _simState = success ? _PaySimState.success : _PaySimState.error);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: Stack(
          children: [
            SafeArea(
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
                          'Paiement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: GabColors.primary,
                          ),
                        ),
                        const Spacer(),
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Text(
                            "Gab'Pharma",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: GabColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: GabColors.outlineVariant),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: GabColors.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Récapitulatif',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text('Commande #${widget.orderNumber}',
                                            style: const TextStyle(
                                                color: GabColors.muted)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA8F4B9),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _formatFcfa(widget.total),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF00210D)),
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                    height: 1, color: GabColors.outlineVariant),
                              ),
                              _SummaryLine('Articles',
                                  _formatFcfa(widget.itemsTotal)),
                              const SizedBox(height: 6),
                              _SummaryLine(
                                  'Livraison', _formatFcfa(widget.deliveryFee)),
                              if (widget.discount > 0) ...[
                                const SizedBox(height: 6),
                                _SummaryLine(
                                  'Réduction (estimation CNAMGS)',
                                  '- ${_formatFcfa(widget.discount)}',
                                  valueColor: GabColors.primary,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Total à payer',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: GabColors.primary),
                                    ),
                                  ),
                                  Text(
                                    _formatFcfa(widget.total),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: GabColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'CHOISIR UN MODE DE PAIEMENT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: GabColors.muted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: [
                            _PaymentMethodTile(
                              icon: Icons.account_balance_wallet,
                              iconBg: const Color(0xFFFFEBEE),
                              iconColor: const Color(0xFFD32F2F),
                              label: 'Airtel Money',
                              selected: _method == _PayMethod.airtel,
                              onTap: () =>
                                  setState(() => _method = _PayMethod.airtel),
                            ),
                            _PaymentMethodTile(
                              icon: Icons.payments,
                              iconBg: const Color(0xFFE3F2FD),
                              iconColor: const Color(0xFF1976D2),
                              label: 'Moov Money',
                              selected: _method == _PayMethod.moov,
                              onTap: () =>
                                  setState(() => _method = _PayMethod.moov),
                            ),
                            _PaymentMethodTile(
                              icon: Icons.credit_card,
                              iconBg: GabColors.softGreen,
                              iconColor: GabColors.primary,
                              label: 'Carte Visa',
                              selected: _method == _PayMethod.visa,
                              onTap: () =>
                                  setState(() => _method = _PayMethod.visa),
                            ),
                            _PaymentMethodTile(
                              icon: Icons.handshake,
                              iconBg: const Color(0xFFFFF3E0),
                              iconColor: const Color(0xFF8D6E00),
                              label: 'Espèces',
                              selected: _method == _PayMethod.cash,
                              onTap: () =>
                                  setState(() => _method = _PayMethod.cash),
                            ),
                          ],
                        ),
                        if (_method != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: GabColors.softGreen,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: GabColors.primary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: _buildMethodDetail(),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 14, color: GabColors.muted),
                            SizedBox(width: 6),
                            Text(
                              'Paiement sécurisé par cryptage SSL 256-bit',
                              style: TextStyle(
                                  color: GabColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: GabColors.outlineVariant)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _method == null ? null : _confirmAndPay,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Confirmer et Payer'),
                            SizedBox(width: 8),
                            Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_simState != _PaySimState.none)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildSimCard(),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildMethodDetail() {
    switch (_method!) {
      case _PayMethod.airtel:
        return _PhoneField(
          controller: _phoneController,
          label: 'Numéro Airtel Money',
          hint: '074 XX XX XX',
        );
      case _PayMethod.moov:
        return _PhoneField(
          controller: _phoneController,
          label: 'Numéro Moov Money',
          hint: '066 XX XX XX',
        );
      case _PayMethod.visa:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Numéro de carte',
                style: TextStyle(
                    fontSize: 12,
                    color: GabColors.muted,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '#### #### #### ####',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cardExpiryController,
                    decoration: const InputDecoration(
                      hintText: 'MM/YY',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cardCvcController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'CVC',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case _PayMethod.cash:
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: GabColors.primary, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Payez directement au livreur lors de la réception de votre commande.',
                style: TextStyle(color: GabColors.muted),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSimCard() {
    switch (_simState) {
      case _PaySimState.none:
        return const SizedBox.shrink();
      case _PaySimState.pending:
        return _SimCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                    strokeWidth: 4, color: GabColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Traitement en cours',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                "Veuillez patienter pendant que nous validons votre transaction auprès de l'opérateur.",
                textAlign: TextAlign.center,
                style: TextStyle(color: GabColors.muted),
              ),
            ],
          ),
        );
      case _PaySimState.success:
        return _SimCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: GabColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: GabColors.primary, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Paiement Réussi !',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Votre commande est maintenant en préparation. Vous recevrez une notification bientôt.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GabColors.muted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderConfirmationScreen(
                        orderReference: widget.orderNumber,
                        pharmacyName: widget.pharmacyName,
                        deliveryLabel: widget.deliveryLabel,
                        deliverySubtitle: widget.deliverySubtitle,
                        totalPaid: widget.total,
                      ),
                    ),
                    (route) => false,
                  ),
                  child: const Text('Voir ma commande'),
                ),
              ),
            ],
          ),
        );
      case _PaySimState.error:
        return _SimCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: GabColors.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    color: GabColors.danger, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Échec du paiement',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: GabColors.danger),
              ),
              const SizedBox(height: 8),
              const Text(
                'Désolé, la transaction a été refusée par votre opérateur. Veuillez réessayer ou utiliser un autre mode.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GabColors.muted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      setState(() => _simState = _PaySimState.none),
                  child: const Text('Réessayer'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => setState(() {
                    _simState = _PaySimState.none;
                    _method = null;
                  }),
                  child: const Text('Changer de mode'),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _SimCard extends StatelessWidget {
  const _SimCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      );
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? GabColors.primary : GabColors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(height: 8),
                    Text(label,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (selected)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.check_circle,
                        color: GabColors.primary, size: 20),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: GabColors.muted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      );
}

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({
    this.orderReference = 'GP-1051',
    this.pharmacyName = 'Pharmacie Akanda',
    this.deliveryLabel = 'Livraison à domicile',
    this.deliverySubtitle = 'Sous 2 à 4 heures · À domicile',
    this.totalPaid = 9090,
    super.key,
  });

  final String orderReference;
  final String pharmacyName;
  final String deliveryLabel;
  final String deliverySubtitle;
  final int totalPaid;

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

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
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [Color(0xFF9DF6B2), GabColors.background],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _ConfettiOverlay(controller: _confettiController),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context, '/home', (route) => false),
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
                          onPressed: () =>
                              Navigator.pushNamed(context, '/notifications'),
                          icon: const Icon(Icons.notifications_outlined,
                              color: GabColors.primary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _confettiController,
                                builder: (context, _) {
                                  final t = _confettiController.value;
                                  final scale = 1 + 0.3 * (1 - t);
                                  return Opacity(
                                    opacity: (1 - t).clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: 128,
                                        height: 128,
                                        decoration: BoxDecoration(
                                          color: GabColors.primary
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                width: 96,
                                height: 96,
                                decoration: const BoxDecoration(
                                  color: GabColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle,
                                    color: Colors.white, size: 52),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Merci pour votre confiance !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: GabColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Votre commande a été transmise avec succès à la pharmacie.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: GabColors.muted),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: GabColors.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'RÉFÉRENCE DE COMMANDE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: GabColors.muted,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '#${widget.orderReference}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(
                                      text: '#${widget.orderReference}'));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Référence copiée dans le presse-papiers.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_outlined,
                                    color: GabColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.local_pharmacy,
                                label: 'Pharmacie',
                                title: widget.pharmacyName,
                                subtitle: 'Libreville, Gabon',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.delivery_dining,
                                label: 'Livraison',
                                title: widget.deliveryLabel,
                                subtitle: widget.deliverySubtitle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: GabColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total payé',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatFcfa(widget.totalPaid),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.payments,
                                    color: Colors.white, size: 26),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/delivery'),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Suivre ma commande'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, '/home', (route) => false),
                            child: const Text("Retour à l'accueil"),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Appel vers 011 70 70 70 — composition indisponible en démonstration.'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: GabColors.background,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                    color: GabColors.outlineVariant),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.support_agent,
                                      size: 16, color: GabColors.muted),
                                  SizedBox(width: 8),
                                  Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                          color: GabColors.muted,
                                          fontSize: 12),
                                      children: [
                                        TextSpan(text: "Besoin d'aide ? Appelez le "),
                                        TextSpan(
                                          text: '011 70 70 70',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
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
                ],
              ),
            ),
          ],
        ),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GabColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: GabColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: GabColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(subtitle,
                style:
                    const TextStyle(color: GabColors.muted, fontSize: 12)),
          ],
        ),
      );
}

class _ConfettiPiece {
  _ConfettiPiece(Random random)
      : x = random.nextDouble(),
        phase = random.nextDouble(),
        speed = 0.6 + random.nextDouble() * 0.8,
        size = 5 + random.nextDouble() * 6,
        swing = random.nextDouble() * 40 - 20,
        color = [
          GabColors.primary,
          const Color(0xFF9DF6B2),
          const Color(0xFF004F26),
          const Color(0xFFFFDEA7),
        ][random.nextInt(4)];

  final double x;
  final double phase;
  final double speed;
  final double size;
  final double swing;
  final Color color;
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({required this.controller});

  final Animation<double> controller;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay> {
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = Random(7);
    _pieces = List.generate(28, (_) => _ConfettiPiece(random));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              for (final piece in _pieces)
                Builder(builder: (context) {
                  final t =
                      (widget.controller.value * piece.speed + piece.phase) %
                          1.0;
                  final dy = t * (constraints.maxHeight + 40) - 20;
                  final dx = piece.x * constraints.maxWidth +
                      sin(t * 2 * pi) * piece.swing;
                  final opacity = t < 0.85 ? 1.0 : (1 - t) / 0.15;
                  return Positioned(
                    left: dx,
                    top: dy,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: t * 6,
                        child: Container(
                          width: piece.size,
                          height: piece.size,
                          color: piece.color,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      );
}

enum _OrderStage { proposal, preparing, delivering, delivered, cancelled }

enum _StepState { done, active, pending, cancelled }

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.time,
    required this.state,
    this.note,
  });

  final String title;
  final String time;
  final _StepState state;
  final String? note;
}

class _OrderLineItem {
  const _OrderLineItem({
    required this.icon,
    required this.name,
    required this.details,
    required this.price,
  });

  final IconData icon;
  final String name;
  final String details;
  final int price;
}

class _OrderDetailData {
  const _OrderDetailData({
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyTags,
    required this.pharmacyPhone,
    required this.items,
    required this.deliveryFee,
    required this.stage,
    required this.steps,
  });

  final String pharmacyName;
  final String pharmacyAddress;
  final List<String> pharmacyTags;
  final String pharmacyPhone;
  final List<_OrderLineItem> items;
  final int deliveryFee;
  final _OrderStage stage;
  final List<_TimelineStep> steps;

  int get subtotal => items.fold(0, (sum, item) => sum + item.price);
  int get total => subtotal + deliveryFee;
}

extension on _OrderStage {
  String get bannerLabel => switch (this) {
        _OrderStage.proposal => 'Proposition Reçue',
        _OrderStage.preparing => 'Préparation en cours',
        _OrderStage.delivering => 'Livraison en cours',
        _OrderStage.delivered => 'Commande livrée',
        _OrderStage.cancelled => 'Commande annulée',
      };

  IconData get bannerIcon => switch (this) {
        _OrderStage.proposal => Icons.notifications_active,
        _OrderStage.preparing => Icons.inventory_2_outlined,
        _OrderStage.delivering => Icons.local_shipping,
        _OrderStage.delivered => Icons.check_circle,
        _OrderStage.cancelled => Icons.cancel,
      };

  Color get bannerColor => switch (this) {
        _OrderStage.cancelled => GabColors.danger,
        _ => GabColors.primary,
      };
}

const _orderDetails = <String, _OrderDetailData>{
  'GP-2607-4218': _OrderDetailData(
    pharmacyName: "Pharmacie de l'Amitié",
    pharmacyAddress: "Libreville, Boulevard de l'Indépendance",
    pharmacyTags: ['Ouvert 24h/24', '1.2 km'],
    pharmacyPhone: '+241 01 76 54 32',
    deliveryFee: 1500,
    stage: _OrderStage.proposal,
    items: [
      _OrderLineItem(
        icon: Icons.medication_outlined,
        name: 'Paracétamol 500mg',
        details: 'Boîte de 16 comprimés × 2',
        price: 4400,
      ),
      _OrderLineItem(
        icon: Icons.vaccines_outlined,
        name: 'Amoxicilline 1g',
        details: 'Gélules × 1',
        price: 5600,
      ),
      _OrderLineItem(
        icon: Icons.medical_services_outlined,
        name: 'Sirop Toplexil',
        details: 'Flacon 150ml × 1',
        price: 3000,
      ),
    ],
    steps: [
      _TimelineStep(
        title: 'Commande envoyée',
        time: "Aujourd'hui, 10:45",
        state: _StepState.done,
      ),
      _TimelineStep(
        title: 'Proposition de la pharmacie',
        time: "Aujourd'hui, 11:10",
        state: _StepState.active,
        note: 'La pharmacie a confirmé la disponibilité des articles.',
      ),
      _TimelineStep(
        title: 'Préparation en cours',
        time: 'En attente de validation',
        state: _StepState.pending,
      ),
      _TimelineStep(
        title: 'Livraison / Retrait',
        time: 'Prévu vers 13:00',
        state: _StepState.pending,
      ),
    ],
  ),
  'GP-2607-4190': _OrderDetailData(
    pharmacyName: "Grande Pharmacie d'Okala",
    pharmacyAddress: 'Libreville, Carrefour Okala',
    pharmacyTags: ['Ouvert 24h/24', '3.4 km'],
    pharmacyPhone: '+241 01 44 22 18',
    deliveryFee: 1500,
    stage: _OrderStage.delivering,
    items: [
      _OrderLineItem(
        icon: Icons.vaccines_outlined,
        name: 'Amoxicilline 1g',
        details: 'Gélules × 1',
        price: 6750,
      ),
    ],
    steps: [
      _TimelineStep(
        title: 'Commande envoyée',
        time: 'Hier, 14:50',
        state: _StepState.done,
      ),
      _TimelineStep(
        title: 'Proposition acceptée',
        time: 'Hier, 15:05',
        state: _StepState.done,
      ),
      _TimelineStep(
        title: 'Préparation terminée',
        time: 'Hier, 15:20',
        state: _StepState.done,
      ),
      _TimelineStep(
        title: 'Livraison en cours',
        time: 'Hier, 15:35',
        state: _StepState.active,
        note: 'Le livreur est en route vers votre adresse.',
      ),
    ],
  ),
  'GP-2606-3980': _OrderDetailData(
    pharmacyName: 'Pharmacie du Centre',
    pharmacyAddress: 'Libreville, Centre-ville',
    pharmacyTags: ['Ouvert 24h/24', '0.8 km'],
    pharmacyPhone: '+241 01 76 54 32',
    deliveryFee: 1500,
    stage: _OrderStage.delivered,
    items: [
      _OrderLineItem(
        icon: Icons.medication_outlined,
        name: 'Paracétamol 500mg',
        details: 'Boîte de 16 comprimés × 2',
        price: 4400,
      ),
      _OrderLineItem(
        icon: Icons.vaccines_outlined,
        name: 'Amoxicilline 1g',
        details: 'Gélules × 1',
        price: 5600,
      ),
      _OrderLineItem(
        icon: Icons.medical_services_outlined,
        name: 'Sirop Toplexil',
        details: 'Flacon 150ml × 1',
        price: 3000,
      ),
      _OrderLineItem(
        icon: Icons.local_pharmacy_outlined,
        name: 'Vitamine C 1000mg',
        details: 'Flacon de 30 comprimés × 1',
        price: 5000,
      ),
      _OrderLineItem(
        icon: Icons.sanitizer_outlined,
        name: 'Biseptine Spray',
        details: 'Flacon 250ml × 1',
        price: 12600,
      ),
    ],
    steps: [
      _TimelineStep(
        title: 'Commande envoyée',
        time: '28 juin 2026, 09:00',
        state: _StepState.done,
      ),
      _TimelineStep(
        title: 'Proposition acceptée',
        time: '28 juin 2026, 09:20',
        state: _StepState.done,
      ),
      _TimelineStep(
        title: 'Préparation terminée',
        time: '28 juin 2026, 10:05',
        state: _StepState.done,
      ),
      _TimelineStep(
        title: 'Livrée',
        time: '28 juin 2026, 11:30',
        state: _StepState.done,
      ),
    ],
  ),
  'GP-2606-3955': _OrderDetailData(
    pharmacyName: "Pharmacie de l'Aéroport",
    pharmacyAddress: 'Libreville, Route de Nzeng-Ayong',
    pharmacyTags: ['08h–20h', '6.1 km'],
    pharmacyPhone: '+241 01 55 30 09',
    deliveryFee: 1500,
    stage: _OrderStage.cancelled,
    items: [
      _OrderLineItem(
        icon: Icons.medication_outlined,
        name: 'Paracétamol 500mg',
        details: 'Boîte de 16 comprimés × 1',
        price: 1700,
      ),
      _OrderLineItem(
        icon: Icons.vaccines_outlined,
        name: 'Amoxicilline 1g',
        details: 'Gélules × 1',
        price: 2200,
      ),
    ],
    steps: [
      _TimelineStep(
        title: 'Commande envoyée',
        time: '20 juin 2026, 09:00',
        state: _StepState.done,
      ),
      _TimelineStep(
        title: 'Commande annulée',
        time: '20 juin 2026, 09:40',
        state: _StepState.cancelled,
        note: 'Annulée par la pharmacie : rupture de stock.',
      ),
    ],
  ),
};

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({this.reference = 'GP-2607-4218', super.key});

  final String reference;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late _OrderStage _stage;
  late List<_TimelineStep> _steps;

  _OrderDetailData get _data =>
      _orderDetails[widget.reference] ?? _orderDetails['GP-2607-4218']!;

  @override
  void initState() {
    super.initState();
    _stage = _data.stage;
    _steps = _data.steps;
  }

  String _formatFcfa(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '$buffer FCFA';
  }

  void _accept() {
    setState(() {
      _stage = _OrderStage.preparing;
      _steps = [
        for (final step in _steps)
          if (step.state == _StepState.active)
            _TimelineStep(
              title: 'Proposition acceptée',
              time: step.time,
              state: _StepState.done,
            )
          else if (step.state == _StepState.pending &&
              step.title == 'Préparation en cours')
            const _TimelineStep(
              title: 'Préparation en cours',
              time: 'En cours',
              state: _StepState.active,
            )
          else
            step,
      ];
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Proposition acceptée. Préparation en cours.'),
    ));
  }

  Future<void> _refuse() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Proposition refusée — commande annulée.'),
    ));
    setState(() => _stage = _OrderStage.cancelled);
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: GabColors.danger),
            child: const Text('Annuler la commande'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      if (!mounted) return;
      setState(() => _stage = _OrderStage.cancelled);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Commande annulée.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: GabColors.background,
      appBar: AppBar(
        title: const Text('Détails de Commande'),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Options indisponibles en démonstration.'),
              ),
            ),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: _stage.bannerColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMMANDE #${widget.reference}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stage.bannerLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(_stage.bannerIcon, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GabColors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: GabColors.softGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_pharmacy,
                      color: GabColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.pharmacyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GabColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: GabColors.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data.pharmacyAddress,
                              style: const TextStyle(
                                  color: GabColors.muted, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final tag in data.pharmacyTags)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: GabColors.softGreen,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: GabColors.secondary),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Appel vers ${data.pharmacyPhone} — composition '
                        'indisponible en démonstration.',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.call, color: GabColors.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: GabColors.softGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GabColors.outlineVariant),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: GabColors.softGreen,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Récapitulatif des articles',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final item in data.items) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: GabColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon,
                              color: GabColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                item.details,
                                style: const TextStyle(
                                    color: GabColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatFcfa(item.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: GabColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item != data.items.last) const Divider(height: 1),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GabColors.background,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sous-total',
                              style: TextStyle(color: GabColors.muted)),
                          Text(_formatFcfa(data.subtotal),
                              style:
                                  const TextStyle(color: GabColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Frais de livraison',
                              style: TextStyle(color: GabColors.muted)),
                          Text(_formatFcfa(data.deliveryFee),
                              style:
                                  const TextStyle(color: GabColors.muted)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: GabColors.primary),
                          ),
                          Text(
                            _formatFcfa(data.total),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: GabColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GabColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suivi de la commande',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _steps.length; i++)
                  _TimelineTile(
                    step: _steps[i],
                    isLast: i == _steps.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_stage == _OrderStage.proposal) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _accept,
                icon: const Icon(Icons.check_circle),
                label: const Text('Accepter la proposition'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _refuse,
                    icon: const Icon(Icons.close),
                    label: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GabColors.danger,
                      side: const BorderSide(color: GabColors.danger),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Annuler la commande'),
                  ),
                ),
              ],
            ),
          ] else if (_stage == _OrderStage.preparing)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: GabColors.danger,
                  side: const BorderSide(color: GabColors.danger),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Annuler la commande'),
              ),
            )
          else if (_stage == _OrderStage.delivering)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pushNamed(context, '/delivery'),
                child: const Text('Suivre la livraison'),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color circleColor = switch (step.state) {
      _StepState.done => GabColors.primary,
      _StepState.active => GabColors.primary,
      _StepState.cancelled => GabColors.danger,
      _StepState.pending => GabColors.outlineVariant,
    };
    final bool faded = step.state == _StepState.pending;
    return Opacity(
      opacity: faded ? 0.5 : 1,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: step.state == _StepState.pending
                        ? Colors.white
                        : circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: circleColor, width: 2),
                  ),
                  child: Icon(
                    switch (step.state) {
                      _StepState.done => Icons.check,
                      _StepState.active => Icons.circle,
                      _StepState.cancelled => Icons.close,
                      _StepState.pending => Icons.circle,
                    },
                    size: step.state == _StepState.active ||
                            step.state == _StepState.pending
                        ? 8
                        : 14,
                    color: step.state == _StepState.pending
                        ? GabColors.outlineVariant
                        : Colors.white,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: GabColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: step.state == _StepState.active
                            ? GabColors.primary
                            : step.state == _StepState.cancelled
                                ? GabColors.danger
                                : GabColors.ink,
                      ),
                    ),
                    Text(
                      step.time,
                      style: const TextStyle(
                          color: GabColors.muted, fontSize: 12),
                    ),
                    if (step.note != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.note!,
                        style: const TextStyle(
                            color: GabColors.muted,
                            fontSize: 13,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCourier {
  const _DeliveryCourier({
    required this.name,
    required this.rating,
    required this.tripsLabel,
  });

  final String name;
  final double rating;
  final String tripsLabel;
}

class _DeliveryTrackingData {
  const _DeliveryTrackingData({
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.destinationLabel,
    required this.destinationDetail,
    required this.etaLabel,
    required this.courier,
    required this.steps,
  });

  final String pharmacyName;
  final String pharmacyAddress;
  final String destinationLabel;
  final String destinationDetail;
  final String etaLabel;
  final _DeliveryCourier courier;
  final List<_TimelineStep> steps;
}

const _deliveryTrackingDefault = _DeliveryTrackingData(
  pharmacyName: "Grande Pharmacie d'Okala",
  pharmacyAddress: 'Libreville, Carrefour Okala',
  destinationLabel: 'Résidence Orchidée, Appt 4B',
  destinationDetail: 'Quartier Louis, Libreville',
  etaLabel: '15:50 (12 min)',
  courier: _DeliveryCourier(
    name: 'Jean M.',
    rating: 4.9,
    tripsLabel: '850+ courses',
  ),
  steps: [
    _TimelineStep(
      title: 'Commande confirmée',
      time: 'Hier, 15:05',
      state: _StepState.done,
    ),
    _TimelineStep(
      title: "Préparée par Grande Pharmacie d'Okala",
      time: 'Hier, 15:20',
      state: _StepState.done,
    ),
    _TimelineStep(
      title: 'En cours de livraison',
      time: 'Hier, 15:35',
      state: _StepState.active,
      note: 'Jean a récupéré votre colis. Code de remise envoyé par SMS '
          '(canal sécurisé).',
    ),
    _TimelineStep(
      title: 'Livrée',
      time: 'Prévu vers 15:50',
      state: _StepState.pending,
    ),
  ],
);

class DeliveryTrackingScreen extends StatelessWidget {
  const DeliveryTrackingScreen({this.reference = 'GP-2607-4190', super.key});

  final String reference;

  @override
  Widget build(BuildContext context) {
    const data = _deliveryTrackingDefault;
    return Scaffold(
      backgroundColor: GabColors.background,
      appBar: AppBar(
        title: const Text('Suivi de Commande'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/support'),
              style: TextButton.styleFrom(
                backgroundColor: GabColors.softGreen,
                foregroundColor: GabColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Support'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GabColors.softGreen,
                      GabColors.primary.withValues(alpha: 0.18),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.map_outlined,
                          size: 120,
                          color: GabColors.primary.withValues(alpha: 0.12)),
                    ),
                    Positioned(
                      left: 32,
                      top: 40,
                      child: _MapPin(
                        icon: Icons.local_pharmacy,
                        background: Colors.white,
                        foreground: GabColors.primary,
                      ),
                    ),
                    const Positioned(
                      right: 40,
                      bottom: 76,
                      child: _MapPin(
                        icon: Icons.electric_moped,
                        background: GabColors.primary,
                        foreground: Colors.white,
                      ),
                    ),
                    Positioned(
                      right: 32,
                      bottom: 20,
                      child: _MapPin(
                        icon: Icons.location_on,
                        background: GabColors.primary,
                        foreground: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ARRIVÉE ESTIMÉE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: GabColors.muted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  data.etaLabel,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: GabColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              'Carte simplifiée, à titre illustratif — position en temps '
              'réel indisponible en démonstration.',
              style: TextStyle(
                fontSize: 11,
                color: GabColors.muted.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GabColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'En route vers vous',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Commande #$reference',
                                  style: const TextStyle(
                                      color: GabColors.muted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: GabColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.electric_moped,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVRAISON EXPRESS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GabColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: GabColors.softGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: GabColors.primary, width: 2),
                              ),
                              child: const Icon(Icons.person,
                                  color: GabColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.courier.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 14,
                                          color:
                                              Color(0xFFFFBB18)),
                                      const SizedBox(width: 2),
                                      Text('${data.courier.rating}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                      const Text(' • ',
                                          style: TextStyle(
                                              color: GabColors.muted)),
                                      Flexible(
                                        child: Text(
                                          data.courier.tripsLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: GabColors.muted),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Appel avec le livreur indisponible en '
                                    'démonstration.',
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.call,
                                  color: Colors.white, size: 18),
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 34, minHeight: 34),
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                backgroundColor: GabColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/support-thread'),
                              icon: const Icon(Icons.chat_bubble_outline,
                                  color: GabColors.muted, size: 18),
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 34, minHeight: 34),
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                backgroundColor: GabColors.background,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GabColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROGRESSION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: GabColors.muted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < data.steps.length; i++)
                        _TimelineTile(
                          step: data.steps[i],
                          isLast: i == data.steps.length - 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _AddressCard(
                        icon: Icons.medication_outlined,
                        iconBackground: Colors.white,
                        iconColor: GabColors.primary,
                        label: "Pharmacie d'origine",
                        title: data.pharmacyName,
                        subtitle: data.pharmacyAddress,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AddressCard(
                        icon: Icons.location_on,
                        iconBackground: GabColors.primary,
                        iconColor: Colors.white,
                        label: 'Destination',
                        title: data.destinationLabel,
                        subtitle: data.destinationDetail,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: foreground, size: 18),
      );
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GabColors.softGreen.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GabColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: GabColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: GabColors.muted, fontSize: 11),
            ),
          ],
        ),
      );
}

enum _PaymentStatus { paid, pending, failed, refundPending, refunded }

extension on _PaymentStatus {
  String get label => switch (this) {
        _PaymentStatus.paid => 'PAYÉ',
        _PaymentStatus.pending => 'EN ATTENTE',
        _PaymentStatus.failed => 'ÉCHEC',
        _PaymentStatus.refundPending => 'REMBOURSEMENT EN COURS',
        _PaymentStatus.refunded => 'REMBOURSÉ',
      };

  IconData get badgeIcon => switch (this) {
        _PaymentStatus.paid => Icons.check_circle,
        _PaymentStatus.pending => Icons.schedule,
        _PaymentStatus.failed => Icons.cancel,
        _PaymentStatus.refundPending => Icons.autorenew,
        _PaymentStatus.refunded => Icons.assignment_return,
      };

  IconData get leadingIcon => switch (this) {
        _PaymentStatus.paid => Icons.medication,
        _PaymentStatus.pending => Icons.hourglass_top,
        _PaymentStatus.failed => Icons.error,
        _PaymentStatus.refundPending => Icons.sync,
        _PaymentStatus.refunded => Icons.undo,
      };

  Color get badgeColor => switch (this) {
        _PaymentStatus.paid => const Color(0xFFA8F4B9),
        _PaymentStatus.pending => const Color(0xFFFFDEA7),
        _PaymentStatus.failed => const Color(0xFFFFDAD6),
        _PaymentStatus.refundPending => const Color(0xFFFFDEA7),
        _PaymentStatus.refunded => const Color(0xFFFFDEA7),
      };

  Color get badgeForeground => switch (this) {
        _PaymentStatus.paid => const Color(0xFF00210D),
        _PaymentStatus.pending => const Color(0xFF5E4200),
        _PaymentStatus.failed => const Color(0xFF93000A),
        _PaymentStatus.refundPending => const Color(0xFF5E4200),
        _PaymentStatus.refunded => const Color(0xFF5E4200),
      };
}

class _FinancialTransaction {
  const _FinancialTransaction({
    required this.pharmacyName,
    required this.referenceLabel,
    required this.dateLabel,
    required this.amount,
    required this.status,
  });

  final String pharmacyName;
  final String referenceLabel;
  final String dateLabel;
  final int amount;
  final _PaymentStatus status;
}

const _financialTransactions = <_FinancialTransaction>[
  _FinancialTransaction(
    pharmacyName: 'Pharmacie de la Garde',
    referenceLabel: 'Commande #GP-2607-5102',
    dateLabel: "Aujourd'hui, 09:05",
    amount: 6800,
    status: _PaymentStatus.pending,
  ),
  _FinancialTransaction(
    pharmacyName: 'Pharmacie Akanda',
    referenceLabel: 'Remboursement #RF-0101',
    dateLabel: '5 juil. 2026, 16:00',
    amount: 1700,
    status: _PaymentStatus.refundPending,
  ),
  _FinancialTransaction(
    pharmacyName: "Pharmacie d'Okala",
    referenceLabel: 'Commande #GP-2607-5031',
    dateLabel: '3 juil. 2026, 14:20',
    amount: 8400,
    status: _PaymentStatus.paid,
  ),
  _FinancialTransaction(
    pharmacyName: 'Pharmacie du Pont',
    referenceLabel: 'Remboursement #RF-0092',
    dateLabel: '1 juil. 2026, 09:15',
    amount: 2500,
    status: _PaymentStatus.refunded,
  ),
  _FinancialTransaction(
    pharmacyName: 'Pharmacie Sainte-Marie',
    referenceLabel: 'Commande #GP-2606-4978',
    dateLabel: '28 juin 2026, 18:45',
    amount: 12000,
    status: _PaymentStatus.failed,
  ),
  _FinancialTransaction(
    pharmacyName: 'Pharmacie Cristal',
    referenceLabel: 'Commande #GP-2606-4899',
    dateLabel: '25 juin 2026, 11:30',
    amount: 15200,
    status: _PaymentStatus.paid,
  ),
];

class PaymentsHistoryScreen extends StatelessWidget {
  const PaymentsHistoryScreen({super.key});

  String _formatFcfa(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '$buffer FCFA';
  }

  void _showRefundInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Processus de remboursement'),
        content: const Text(
          'Les remboursements sont traités sous 3 à 5 jours ouvrables '
          "après validation par Gab'Pharma. Le montant est crédité sur "
          "le moyen de paiement d'origine (Mobile Money ou carte). Le "
          'remboursement effectif reste géré manuellement tant que la '
          "passerelle de paiement n'est pas connectée.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paidTotal = _financialTransactions
        .where((t) => t.status == _PaymentStatus.paid)
        .fold(0, (sum, t) => sum + t.amount);
    final refundedTotal = _financialTransactions
        .where((t) => t.status == _PaymentStatus.refunded)
        .fold(0, (sum, t) => sum + t.amount);
    return Scaffold(
      backgroundColor: GabColors.background,
      appBar: AppBar(
        title: const Text('Paiements & Remboursements'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/support'),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GabColors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DÉPENSES TOTALES (MOIS)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: GabColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFcfa(paidTotal),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: GabColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9DF6B2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: GabColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Remboursements',
                  value: _formatFcfa(refundedTotal),
                  valueColor: GabColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Transactions',
                  value: '${_financialTransactions.length}',
                  valueColor: GabColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GabColors.softGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: GabColors.secondary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: GabColors.secondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Processus de remboursement',
                        style: TextStyle(
                            color: GabColors.secondary,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Les remboursements sont traités sous 3 à 5 jours '
                        "ouvrables après validation par Gab'Pharma. Le "
                        "montant sera crédité sur votre compte d'origine.",
                        style: TextStyle(
                            color: GabColors.muted, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => _showRefundInfo(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: GabColors.secondary,
                        ),
                        child: const Text('En savoir plus'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historique financier',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Filtres indisponibles en démonstration.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Filtrer'),
                style: TextButton.styleFrom(foregroundColor: GabColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final tx in _financialTransactions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TransactionCard(
                tx: tx,
                formatFcfa: _formatFcfa,
                onResumePayment: () =>
                    Navigator.pushNamed(context, '/payment'),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: GabColors.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: GabColors.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.contact_support,
                      color: GabColors.primary, size: 30),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Un problème avec un paiement ?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Notre service client est disponible 24h/24 pour '
                  'résoudre vos litiges financiers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GabColors.muted),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pushNamed(context, '/support'),
                    child: const Text('Contacter le support'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GabColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: GabColors.muted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.tx,
    required this.formatFcfa,
    required this.onResumePayment,
  });

  final _FinancialTransaction tx;
  final String Function(int) formatFcfa;
  final VoidCallback onResumePayment;

  @override
  Widget build(BuildContext context) {
    final isRefund = tx.status == _PaymentStatus.refunded ||
        tx.status == _PaymentStatus.refundPending;
    final isFailed = tx.status == _PaymentStatus.failed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GabColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tx.status.badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tx.status.leadingIcon,
                    color: tx.status.badgeForeground, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.pharmacyName,
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                    Text(tx.referenceLabel,
                        style: const TextStyle(
                            color: GabColors.muted, fontSize: 12)),
                    Text(tx.dateLabel,
                        style: const TextStyle(
                            color: GabColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isRefund
                        ? '+${formatFcfa(tx.amount)}'
                        : formatFcfa(tx.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: isFailed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isFailed
                          ? GabColors.muted.withValues(alpha: 0.6)
                          : isRefund
                              ? GabColors.secondary
                              : GabColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: tx.status.badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tx.status.badgeIcon,
                              size: 11, color: tx.status.badgeForeground),
                          const SizedBox(width: 3),
                          Text(
                            tx.status.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: tx.status.badgeForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (tx.status == _PaymentStatus.pending) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onResumePayment,
                child: const Text('Reprendre le paiement'),
              ),
            ),
          ],
        ],
      ),
    );
  }
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

enum _StockStatus { inStock, lowStock, outOfStock }

class _FavoriteItem {
  _FavoriteItem({
    required this.name,
    required this.details,
    required this.price,
    required this.stock,
    this.isFavorite = true,
  });

  final String name;
  final String details;
  final int? price;
  final _StockStatus stock;
  bool isFavorite;
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

enum _FavoritesSort { recent, name, price }

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _queryController = TextEditingController();
  _FavoritesSort _sort = _FavoritesSort.recent;

  final _items = [
    _FavoriteItem(
      name: 'Doliprane 1000mg',
      details: 'Boîte de 8 gélules',
      price: 2450,
      stock: _StockStatus.inStock,
    ),
    _FavoriteItem(
      name: 'Vitamine C 500mg',
      details: 'Flacon de 30 comprimés',
      price: 5000,
      stock: _StockStatus.lowStock,
    ),
    _FavoriteItem(
      name: 'Biafine Emulsion',
      details: 'Tube de 93g',
      price: null,
      stock: _StockStatus.outOfStock,
    ),
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  String _formatFcfa(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '$buffer FCFA';
  }

  List<_FavoriteItem> get _visibleItems {
    final query = _queryController.text.trim().toLowerCase();
    final list = query.isEmpty
        ? [..._items]
        : _items
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
    switch (_sort) {
      case _FavoritesSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _FavoritesSort.price:
        list.sort((a, b) => (a.price ?? 1 << 30)
            .compareTo(b.price ?? 1 << 30));
      case _FavoritesSort.recent:
        break;
    }
    return list;
  }

  void _removeItem(_FavoriteItem item) {
    final index = _items.indexOf(item);
    setState(() => _items.remove(item));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} retiré des favoris.'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => setState(() => _items.insert(
              index.clamp(0, _items.length), item)),
        ),
      ),
    );
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
                      'Favoris',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<_FavoritesSort>(
                      icon: const Icon(Icons.more_vert,
                          color: GabColors.primary),
                      onSelected: (value) => setState(() => _sort = value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _FavoritesSort.recent,
                          child: Text('Récemment ajoutés'),
                        ),
                        PopupMenuItem(
                          value: _FavoritesSort.name,
                          child: Text('Trier par nom'),
                        ),
                        PopupMenuItem(
                          value: _FavoritesSort.price,
                          child: Text('Trier par prix'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GabColors.outlineVariant),
              Expanded(
                child: _items.isEmpty
                    ? _EmptyFavorites(
                        onBrowse: () => Navigator.pop(context),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          TextField(
                            controller: _queryController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Rechercher dans vos favoris',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (final item in _visibleItems)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _FavoriteCard(
                                item: item,
                                formatFcfa: _formatFcfa,
                                onToggleFavorite: () => setState(
                                    () => item.isFavorite = !item.isFavorite),
                                onDelete: () => _removeItem(item),
                                onAddToCart: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${item.name} ajouté au panier (démo).'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                onTap: () =>
                                    Navigator.pushNamed(context, '/medication'),
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

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.item,
    required this.formatFcfa,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onAddToCart,
    required this.onTap,
  });

  final _FavoriteItem item;
  final String Function(int) formatFcfa;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outOfStock = item.stock == _StockStatus.outOfStock;
    return Opacity(
      opacity: outOfStock ? 0.7 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GabColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: outOfStock
                            ? GabColors.background
                            : GabColors.softGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication_outlined,
                        color: outOfStock
                            ? GabColors.muted
                            : GabColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(item.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ),
                              IconButton(
                                onPressed: onToggleFavorite,
                                icon: Icon(
                                  item.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: item.isFavorite
                                      ? GabColors.primary
                                      : GabColors.muted,
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          Text(item.details,
                              style: const TextStyle(
                                  color: GabColors.muted, fontSize: 12)),
                          const SizedBox(height: 8),
                          if (outOfStock)
                            const Text(
                              'Rupture de stock',
                              style: TextStyle(
                                color: GabColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  formatFcfa(item.price!),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: GabColors.primary,
                                  ),
                                ),
                                _StockChip(status: item.stock),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: GabColors.outlineVariant),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: outOfStock
                            ? FilledButton.tonal(
                                onPressed: null,
                                style: FilledButton.styleFrom(
                                  disabledBackgroundColor:
                                      GabColors.background,
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.remove_shopping_cart_outlined,
                                        size: 18),
                                    SizedBox(width: 8),
                                    Text('Indisponible'),
                                  ],
                                ),
                              )
                            : FilledButton.tonal(
                                onPressed: onAddToCart,
                                style: FilledButton.styleFrom(
                                  backgroundColor: GabColors.softGreen,
                                  foregroundColor: GabColors.primary,
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined,
                                        size: 18),
                                    SizedBox(width: 8),
                                    Text('Ajouter au panier'),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(
                              color: GabColors.outlineVariant),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: GabColors.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.status});

  final _StockStatus status;

  @override
  Widget build(BuildContext context) {
    final lowStock = status == _StockStatus.lowStock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: lowStock
            ? const Color(0xFFFFDAD6)
            : const Color(0xFFA8F4B9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            lowStock ? Icons.warning_amber_rounded : Icons.check_circle,
            size: 13,
            color: lowStock ? const Color(0xFF93000A) : const Color(0xFF287243),
          ),
          const SizedBox(width: 4),
          Text(
            lowStock ? 'Stock limité' : 'En stock',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: lowStock ? const Color(0xFF93000A) : const Color(0xFF287243),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: GabColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite,
                    size: 64, color: GabColors.primary.withValues(alpha: 0.3)),
              ),
              const SizedBox(height: 24),
              const Text(
                "Aucun favori pour l'instant",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enregistrez vos médicaments habituels pour les retrouver '
                'facilement et suivre leurs prix.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GabColors.muted),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onBrowse,
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text('Parcourir les produits'),
              ),
            ],
          ),
        ),
      );
}
