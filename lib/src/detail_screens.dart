import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_screens.dart' show TermsScreen, PrivacyPolicyScreen;
import 'core/api_client.dart' show ApiException;
import 'core/auth_session.dart';
import 'core/patient_catalog.dart';
import 'core/theme.dart';
import 'widgets.dart' show EmptyState, addToCartWithFeedback;

class _MedicationPharmacy {
  const _MedicationPharmacy({
    required this.stockId,
    required this.pharmacyId,
    required this.name,
    required this.location,
    required this.price,
    required this.inStock,
    required this.stockLabel,
    required this.stockLow,
  });

  final int stockId;
  final int pharmacyId;
  final String name;
  final String location;
  final int price;
  final bool inStock;
  final String stockLabel;
  final bool stockLow;
}

class MedicationDetailScreen extends StatefulWidget {
  const MedicationDetailScreen({super.key});

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  int? _stockId;
  CatalogStock? _stock;
  List<_MedicationPharmacy> _pharmacies = [];
  int _selectedPharmacy = 0;
  int _quantity = 1;
  bool _loading = true;
  String? _error;
  bool? _favoriteOverride;
  bool _favoriteBusy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stockId == null) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      _stockId = arg is int ? arg : null;
      _load();
    }
  }

  _MedicationPharmacy _toOption(CatalogStock stock) => _MedicationPharmacy(
        stockId: stock.id,
        pharmacyId: stock.pharmacy.id,
        name: stock.pharmacy.name,
        location: stock.pharmacy.zoneLabel,
        price: stock.priceFcfa,
        inStock: stock.inStock,
        stockLabel: stock.isLowStock
            ? 'Stock limité (${stock.quantity})'
            : 'Stock: ${stock.quantity}',
        stockLow: stock.isLowStock,
      );

  Future<void> _load() async {
    final stockId = _stockId;
    if (stockId == null) {
      setState(() {
        _loading = false;
        _error = 'Article introuvable.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stock = await fetchStockDetail(stockId);
      final page = await fetchCatalog(query: stock.medication.name);
      if (!mounted) return;
      final pharmacies = page.results.map(_toOption).toList();
      final selectedIndex =
          pharmacies.indexWhere((p) => p.pharmacyId == stock.pharmacy.id);
      setState(() {
        _stock = stock;
        _pharmacies = pharmacies.isEmpty ? [_toOption(stock)] : pharmacies;
        _selectedPharmacy = selectedIndex >= 0 ? selectedIndex : 0;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Impossible de joindre l'API Gab'Pharma.";
      });
    }
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

  void _showNotConnected(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  bool get _isFavorite => _favoriteOverride ?? _stock?.medication.isFavorite ?? false;

  Future<void> _toggleFavorite() async {
    final stock = _stock;
    if (stock == null || _favoriteBusy) return;
    final currentlyFavorite = _isFavorite;
    setState(() => _favoriteBusy = true);
    try {
      if (currentlyFavorite) {
        final favorites = await fetchFavorites();
        final match = favorites.where(
            (f) => f.medication.medicationId == stock.medication.medicationId);
        if (match.isNotEmpty) await removeFavorite(match.first.id);
      } else {
        await addFavorite(stock.medication.medicationId);
      }
      if (!mounted) return;
      setState(() {
        _favoriteOverride = !currentlyFavorite;
        _favoriteBusy = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _favoriteBusy = false);
      _showNotConnected('Impossible de mettre à jour les favoris pour le moment.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = _stock;
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
                    icon:
                        const Icon(Icons.arrow_back, color: GabColors.primary),
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
                    onPressed: stock == null ? null : _toggleFavorite,
                    icon: _favoriteBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
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
            Expanded(child: _buildBody(context)),
            if (stock != null) _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off,
                  size: 52, color: GabColors.secondary),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    final stock = _stock!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
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
                  Expanded(
                    child: Text(
                      stock.medication.name,
                      style: const TextStyle(
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
                      color: stock.inStock
                          ? const Color(0xFFA8F4B9)
                          : GabColors.softGreen,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      stock.inStock ? 'En Stock' : 'Épuisé',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: stock.inStock
                            ? const Color(0xFF287243)
                            : GabColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              if (stock.medication.dci.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(stock.medication.dci,
                    style: const TextStyle(
                        fontSize: 18, color: GabColors.muted)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (stock.medication.dosage.isNotEmpty)
                    _InfoTag(stock.medication.dosage),
                  if (stock.medication.formLabel.isNotEmpty)
                    _InfoTag(stock.medication.formLabel),
                  if (stock.medication.requiresPrescription)
                    const _InfoTag('Ordonnance requise'),
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
                  Text(
                      _pharmacies.length > 1
                          ? '${_pharmacies.length} trouvées'
                          : '${_pharmacies.length} trouvée',
                      style: const TextStyle(color: GabColors.muted)),
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
                    onTap: () => setState(() => _selectedPharmacy = i),
                    onOpenDetail: () => Navigator.pushNamed(
                        context, '/pharmacy',
                        arguments: _pharmacies[i].pharmacyId),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: GabColors.outlineVariant)),
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
                        constraints:
                            const BoxConstraints(minWidth: 44, minHeight: 44),
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
                        constraints:
                            const BoxConstraints(minWidth: 44, minHeight: 44),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => addToCartWithFeedback(
                        context,
                        _pharmacies[_selectedPharmacy].stockId,
                        quantity: _quantity,
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Ajouter au panier'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
                              pharmacy.location,
                              style: const TextStyle(color: GabColors.muted),
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

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PatientCart? _cart;
  List<PatientZone> _zones = const [];
  List<PatientPaymentMethod> _paymentMethods = const [];
  String? _selectedZoneCode;
  int? _selectedPaymentMethodId;
  _DeliveryMethod _deliveryMethod = _DeliveryMethod.home;
  final _addressDetails = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  PatientCheckoutResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addressDetails.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        fetchCart(),
        fetchPatientZones(),
        fetchPaymentMethods(),
      ]);
      if (!mounted) return;
      final zones = results[1] as List<PatientZone>;
      final paymentMethods = results[2] as List<PatientPaymentMethod>;
      setState(() {
        _cart = results[0] as PatientCart;
        _zones = zones;
        _paymentMethods = paymentMethods;
        _selectedZoneCode = zones.isNotEmpty ? zones.first.code : null;
        _selectedPaymentMethodId =
            paymentMethods.isNotEmpty ? paymentMethods.first.id : null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Impossible de joindre l'API Gab'Pharma.";
      });
    }
  }

  bool get _canSubmit =>
      !_submitting &&
      _cart != null &&
      !_cart!.isEmpty &&
      _cart!.isValidForCheckout &&
      _selectedPaymentMethodId != null &&
      (_deliveryMethod == _DeliveryMethod.pickup || _zones.isNotEmpty);

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

  Widget _paymentMethodIcon(String kind) {
    Color bg = GabColors.primary;
    Color fg = Colors.white;
    IconData icon = Icons.payments_outlined;
    switch (kind) {
      case 'airtel_money':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        icon = Icons.account_balance_wallet;
      case 'moov_money':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1976D2);
        icon = Icons.payments;
      case 'visa':
        bg = GabColors.softGreen;
        fg = GabColors.primary;
        icon = Icons.credit_card;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: 18),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final deliveryAddress = _addressDetails.text.trim();
    final deliveryZone =
        _deliveryMethod == _DeliveryMethod.home ? (_selectedZoneCode ?? '') : '';
    if (_deliveryMethod == _DeliveryMethod.home) {
      if (deliveryAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Renseignez une adresse pour la livraison.')),
        );
        return;
      }
      if (deliveryZone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez la zone de livraison.')),
        );
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      final result = await checkoutPatientCart(
        deliveryMode:
            _deliveryMethod == _DeliveryMethod.home ? 'delivery' : 'pickup',
        deliveryAddress: deliveryAddress,
        deliveryZone: deliveryZone,
        paymentMethodId: _selectedPaymentMethodId!,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _result = result;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Impossible de confirmer la commande pour le moment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) return _buildSuccess(result);
    return Scaffold(
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
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cart = _cart;
    if (_loading && cart == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && cart == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 52, color: GabColors.secondary),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    if (cart == null || cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 52, color: GabColors.muted),
              const SizedBox(height: 16),
              const Text('Votre panier est vide.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour au panier'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _CheckoutCard(
          icon: Icons.inventory_2_outlined,
          title: 'Méthode de réception',
          child: Column(
            children: [
              _OptionCard(
                icon: Icons.home_outlined,
                title: 'Livraison à domicile',
                subtitle: 'Frais calculés à la confirmation',
                selected: _deliveryMethod == _DeliveryMethod.home,
                onTap: () =>
                    setState(() => _deliveryMethod = _DeliveryMethod.home),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                icon: Icons.storefront_outlined,
                title: 'Retrait en pharmacie',
                subtitle: 'Sur place, sans frais de livraison',
                trailing: 'Gratuit',
                selected: _deliveryMethod == _DeliveryMethod.pickup,
                onTap: () =>
                    setState(() => _deliveryMethod = _DeliveryMethod.pickup),
              ),
            ],
          ),
        ),
        if (_deliveryMethod == _DeliveryMethod.home) ...[
          const SizedBox(height: 16),
          _CheckoutCard(
            icon: Icons.local_shipping_outlined,
            title: 'Adresse de livraison',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_zones.isEmpty)
                  const Text(
                    'Aucune zone de livraison active pour le moment — choisissez le retrait en pharmacie.',
                    style: TextStyle(color: GabColors.muted),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final zone in _zones)
                        _SelectableChip(
                          label: zone.label,
                          selected: _selectedZoneCode == zone.code,
                          onTap: () =>
                              setState(() => _selectedZoneCode = zone.code),
                        ),
                    ],
                  ),
                const SizedBox(height: 14),
                const Text(
                  "Précisions sur l'adresse (Quartier, Immeuble, Repères)",
                  style: TextStyle(fontSize: 12, color: GabColors.muted),
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
        ],
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
              Icon(Icons.info_outline, color: GabColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Si vous êtes affilié(e) à une assurance acceptée par cette pharmacie, la réduction est calculée automatiquement et apparaîtra dans le récapitulatif final.',
                  style: TextStyle(color: GabColors.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CheckoutCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Mode de paiement',
          child: _paymentMethods.isEmpty
              ? const Text(
                  'Aucun moyen de paiement actif pour le moment.',
                  style: TextStyle(color: GabColors.muted),
                )
              : Column(
                  children: [
                    for (final method in _paymentMethods) ...[
                      _OptionCard(
                        leading: _paymentMethodIcon(method.kind),
                        title: method.label,
                        selected: _selectedPaymentMethodId == method.id,
                        onTap: () => setState(
                            () => _selectedPaymentMethodId = method.id),
                      ),
                      if (method != _paymentMethods.last)
                        const SizedBox(height: 10),
                    ],
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final item in cart.items)
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
                        child: Text('${item.quantity}x',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.stock.medication.name)),
                      Text(_formatFcfa(item.lineTotalFcfa),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: GabColors.outlineVariant),
              ),
              _SummaryLine('Sous-total', _formatFcfa(cart.subtotalFcfa)),
              const SizedBox(height: 6),
              _SummaryLine(
                'Frais de livraison',
                _deliveryMethod == _DeliveryMethod.pickup
                    ? 'Gratuit'
                    : 'Calculés à la confirmation',
              ),
              const SizedBox(height: 10),
              const Text(
                'Le total exact (frais de livraison et réduction assurance éventuelle inclus) est confirmé après validation de la commande.',
                style: TextStyle(fontSize: 12, color: GabColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
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
            Icon(Icons.shield_outlined, size: 14, color: GabColors.muted),
            SizedBox(width: 6),
            Text('Paiement 100% sécurisé',
                style: TextStyle(color: GabColors.muted, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccess(PatientCheckoutResult result) {
    final order = result.order;
    return Scaffold(
      backgroundColor: GabColors.background,
      body: SafeArea(
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
                    'Commande créée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GabColors.primary,
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
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: GabColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle,
                          color: Colors.white, size: 48),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    result.paymentRequired
                        ? 'Commande transmise à ${order.pharmacyName}'
                        : 'Commande confirmée chez ${order.pharmacyName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary),
                  ),
                  const SizedBox(height: 24),
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
                        const Text('RÉFÉRENCE DE COMMANDE',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: GabColors.muted,
                                letterSpacing: 0.6)),
                        const SizedBox(height: 4),
                        Text('#${order.reference}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        _SummaryLine('Livraison', order.deliveryModeLabel),
                        const SizedBox(height: 6),
                        _SummaryLine(
                            'Sous-total', _formatFcfa(order.subtotalFcfa)),
                        const SizedBox(height: 6),
                        _SummaryLine('Frais de livraison',
                            _formatFcfa(order.deliveryFeeFcfa)),
                        if (order.insuranceDiscountFcfa > 0) ...[
                          const SizedBox(height: 6),
                          _SummaryLine(
                            'Réduction assurance',
                            '- ${_formatFcfa(order.insuranceDiscountFcfa)}',
                            valueColor: GabColors.primary,
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(
                              height: 1, color: GabColors.outlineVariant),
                        ),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Total',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Text(_formatFcfa(order.totalFcfa),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: GabColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Statut du paiement : ${order.paymentStatusLabel}',
                            style: const TextStyle(
                                fontSize: 12, color: GabColors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: result.paymentRequired
                          ? const Color(0xFFFFF3E0)
                          : GabColors.softGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          result.paymentRequired
                              ? Icons.hourglass_top
                              : Icons.check_circle_outline,
                          color: result.paymentRequired
                              ? const Color(0xFF8D6E00)
                              : GabColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            result.paymentRequired
                                ? "Paiement en attente. Aucune passerelle réelle n'est branchée : simulez l'issue du paiement pour finaliser la commande."
                                : 'Paiement à régler à la réception, comme demandé.',
                            style: const TextStyle(color: GabColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (result.paymentRequired &&
                      result.paymentTransactionReference != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SimulatedPaymentScreen(
                              transactionReference:
                                  result.paymentTransactionReference!,
                              orderReference: order.reference,
                              pharmacyName: order.pharmacyName,
                              totalFcfa: order.totalFcfa,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Simuler le paiement'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false),
                      child: const Text("Retour à l'accueil"),
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
}

/// Résolution réelle des transactions créées par `MobilePatientCheckoutView`
/// pour les moyens de paiement en ligne (Airtel/Moov/Visa) : aucune
/// passerelle de paiement réelle n'est branchée côté backend en dev, donc
/// l'API elle-même expose cet endpoint de simulation — ce n'est pas une
/// simulation locale comme l'ancien `PaymentScreen`.
class SimulatedPaymentScreen extends StatefulWidget {
  const SimulatedPaymentScreen({
    required this.transactionReference,
    required this.orderReference,
    required this.pharmacyName,
    required this.totalFcfa,
    super.key,
  });

  final String transactionReference;
  final String orderReference;
  final String pharmacyName;
  final int totalFcfa;

  @override
  State<SimulatedPaymentScreen> createState() =>
      _SimulatedPaymentScreenState();
}

class _SimulatedPaymentScreenState extends State<SimulatedPaymentScreen> {
  bool _resolving = false;
  PatientPaymentResolution? _resolution;
  String? _error;

  String _formatFcfa(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '$buffer FCFA';
  }

  Future<void> _resolve(bool succeeded) async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final resolution = await resolveSimulatedPayment(
        reference: widget.transactionReference,
        succeeded: succeeded,
      );
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _resolution = resolution;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = "Impossible de joindre l'API Gab'Pharma.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolution = _resolution;
    return Scaffold(
      backgroundColor: GabColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  if (resolution == null)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: GabColors.primary),
                    )
                  else
                    const SizedBox(width: 16),
                  const Text(
                    'Paiement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GabColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: GabColors.outlineVariant),
            Expanded(
              child:
                  resolution != null ? _buildResult(resolution) : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                const Text('COMMANDE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: GabColors.muted,
                        letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text('#${widget.orderReference}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _SummaryLine('Pharmacie', widget.pharmacyName),
                const SizedBox(height: 6),
                _SummaryLine('Total', _formatFcfa(widget.totalFcfa)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined,
                    color: Color(0xFF8D6E00), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Environnement de test : aucune passerelle de paiement réelle n'est branchée. Choisissez l'issue à simuler, comme le ferait un vrai paiement Mobile Money ou carte selon qu'il passe ou échoue.",
                    style: TextStyle(color: GabColors.muted),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: GabColors.danger),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _resolving ? null : () => _resolve(true),
              child: _resolving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simuler un paiement réussi'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _resolving ? null : () => _resolve(false),
              child: const Text('Simuler un paiement échoué'),
            ),
          ),
        ],
      );

  Widget _buildResult(PatientPaymentResolution resolution) {
    final succeeded = resolution.transaction.succeeded;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: succeeded ? GabColors.primary : GabColors.danger,
              shape: BoxShape.circle,
            ),
            child: Icon(
              succeeded ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          succeeded ? 'Paiement réussi' : 'Paiement échoué',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: succeeded ? GabColors.primary : GabColors.danger,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Commande #${resolution.order.reference} · ${resolution.transaction.statusLabel}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: GabColors.muted),
        ),
        const SizedBox(height: 24),
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
              _SummaryLine('Pharmacie', resolution.order.pharmacyName),
              const SizedBox(height: 6),
              _SummaryLine('Total', _formatFcfa(resolution.order.totalFcfa)),
              const SizedBox(height: 6),
              _SummaryLine(
                  'Statut du paiement', resolution.order.paymentStatusLabel),
            ],
          ),
        ),
        if (!succeeded) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "Vous pourrez retenter le paiement depuis le suivi de commande, une fois cet écran branché à l'API (prochain module).",
              style: TextStyle(color: GabColors.muted),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false),
            child: const Text("Retour à l'accueil"),
          ),
        ),
      ],
    );
  }
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
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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
                fontWeight:
                    valueColor != null ? FontWeight.w700 : FontWeight.w400,
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
    setState(
        () => _simState = success ? _PaySimState.success : _PaySimState.error);
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
                                      borderRadius: BorderRadius.circular(999),
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
                              _SummaryLine(
                                  'Articles', _formatFcfa(widget.itemsTotal)),
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
                                  color:
                                      GabColors.primary.withValues(alpha: 0.2)),
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
                  border:
                      Border(top: BorderSide(color: GabColors.outlineVariant)),
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
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                border:
                                    Border.all(color: GabColors.outlineVariant),
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
                                          color: GabColors.muted, fontSize: 12),
                                      children: [
                                        TextSpan(
                                            text:
                                                "Besoin d'aide ? Appelez le "),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(subtitle,
                style: const TextStyle(color: GabColors.muted, fontSize: 12)),
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
                    child: Icon(_stage.bannerIcon, color: Colors.white),
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
                              style: const TextStyle(color: GabColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Frais de livraison',
                              style: TextStyle(color: GabColors.muted)),
                          Text(_formatFcfa(data.deliveryFee),
                              style: const TextStyle(color: GabColors.muted)),
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
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                      style:
                          const TextStyle(color: GabColors.muted, fontSize: 12),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          size: 14, color: Color(0xFFFFBB18)),
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
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ConversationScreen(
                                    ticketReference: 'TK-45920',
                                  ),
                                ),
                              ),
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
              border:
                  Border.all(color: GabColors.secondary.withValues(alpha: 0.2)),
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
                        style: TextStyle(color: GabColors.muted, fontSize: 13),
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
                onResumePayment: () => Navigator.pushNamed(context, '/payment'),
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
                style: const TextStyle(color: GabColors.muted, fontSize: 12)),
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
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _InsurerInfo {
  const _InsurerInfo({
    required this.name,
    required this.defaultRate,
    required this.exceptions,
  });

  final String name;
  final double defaultRate;
  final List<String> exceptions;
}

const _insurers = <_InsurerInfo>[
  _InsurerInfo(
    name: 'CNAMGS',
    defaultRate: 0.8,
    exceptions: [
      'Médicaments de confort non remboursés',
      'Plafond mensuel : 150 000 FCFA',
    ],
  ),
  _InsurerInfo(
    name: 'AXA Gabon',
    defaultRate: 0.7,
    exceptions: ['Génériques : ticket modérateur de 20 %'],
  ),
  _InsurerInfo(
    name: 'Allianz Gabon',
    defaultRate: 0.75,
    exceptions: ['Médicaments hors liste : couverture à 50 %'],
  ),
  _InsurerInfo(
    name: 'Ascoma',
    defaultRate: 0.65,
    exceptions: ['Franchise annuelle de 20 000 FCFA'],
  ),
  _InsurerInfo(
    name: 'SUNU Assurances',
    defaultRate: 0.7,
    exceptions: ['Parapharmacie exclue de la couverture'],
  ),
];

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  _InsurerInfo? _savedInsurer;
  String? _savedPlan;
  String? _savedMemberNumber;

  _InsurerInfo? _insurer;
  final _planController = TextEditingController();
  final _memberController = TextEditingController();

  bool get _hasProfile => _savedInsurer != null;

  @override
  void initState() {
    super.initState();
    _savedInsurer = _insurers.first;
    _savedPlan = 'Formule Confort';
    _savedMemberNumber = 'CNAM-2026-0417';
  }

  @override
  void dispose() {
    _planController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _insurer = _savedInsurer;
      _planController.text = _savedPlan ?? '';
      _memberController.text = _savedMemberNumber ?? '';
    });
  }

  void _save() {
    if (_insurer == null || _memberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Choisissez un assureur et indiquez votre numéro '
            'de membre.'),
      ));
      return;
    }
    setState(() {
      _savedInsurer = _insurer;
      _savedPlan = _planController.text.trim();
      _savedMemberNumber = _memberController.text.trim();
      _insurer = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Profil assurance enregistré.'),
    ));
  }

  Future<void> _withdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer mon affiliation ?'),
        content: const Text(
          'Vos remboursements en pharmacie ne seront plus estimés avec '
          'un taux de couverture tant que vous ne redéclarez pas une '
          'assurance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: GabColors.danger),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      setState(() {
        _savedInsurer = null;
        _savedPlan = null;
        _savedMemberNumber = null;
        _insurer = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Affiliation retirée.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _insurer != null || !_hasProfile;
    return Scaffold(
      backgroundColor: GabColors.background,
      appBar: AppBar(
        title: const Text('Mon assurance'),
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
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GabColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion Santé',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Configurez vos informations de couverture pour '
                  'faciliter vos remboursements en pharmacie.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      _hasProfile ? 'ACTIF' : 'NON CONFIGURÉ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_hasProfile && !isEditing) ...[
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
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: GabColors.softGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.corporate_fare,
                            color: GabColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_savedInsurer!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            if ((_savedPlan ?? '').isNotEmpty)
                              Text(_savedPlan!,
                                  style: const TextStyle(
                                      color: GabColors.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _startEditing,
                        icon: const Icon(Icons.edit_outlined,
                            color: GabColors.primary),
                        tooltip: 'Modifier',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('N° de membre : ${_savedMemberNumber ?? "—"}',
                      style: const TextStyle(
                          color: GabColors.muted, fontSize: 13)),
                  const SizedBox(height: 16),
                  _CoverageEstimate(insurer: _savedInsurer!),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _withdraw,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GabColors.danger,
                        side: const BorderSide(color: GabColors.danger),
                      ),
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Retirer mon affiliation'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text('Assureur',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<_InsurerInfo>(
              initialValue: _insurer,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.corporate_fare),
                hintText: 'Choisir un assureur',
              ),
              items: [
                for (final insurer in _insurers)
                  DropdownMenuItem(value: insurer, child: Text(insurer.name)),
              ],
              onChanged: (value) => setState(() => _insurer = value),
            ),
            const SizedBox(height: 16),
            const Text("Nom de l'offre / Plan",
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _planController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.medical_services_outlined),
                hintText: 'Ex : Formule Confort',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Numéro de membre',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _memberController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: 'XXXX-XXXX-XXXX',
              ),
            ),
            const SizedBox(height: 16),
            if (_insurer != null)
              _CoverageEstimate(insurer: _insurer!)
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GabColors.softGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: GabColors.secondary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimation de couverture',
                            style: TextStyle(
                                color: GabColors.secondary,
                                fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Le montant estimé à payer sera calculé '
                            'automatiquement sur la base de votre taux '
                            'de couverture habituel déclaré par votre '
                            'assureur.',
                            style:
                                TextStyle(color: GabColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer mon profil'),
              ),
            ),
            if (_hasProfile) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _insurer = null;
                    _planController.clear();
                    _memberController.clear();
                  }),
                  child: const Text('Annuler'),
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          if (_hasProfile && !isEditing)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Une seule affiliation active à la fois en '
                      'démonstration.',
                    ),
                  ),
                ),
                child: const Text('Ajouter une autre assurance'),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Ces informations sont déclaratives : Gab\'Pharma ne vérifie '
            'pas vos droits auprès de votre assureur. Le montant réel '
            'remboursé dépend de votre contrat et de votre assureur.',
            style: TextStyle(color: GabColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CoverageEstimate extends StatelessWidget {
  const _CoverageEstimate({required this.insurer});

  final _InsurerInfo insurer;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GabColors.softGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        'Estimation de couverture',
                        style: TextStyle(
                            color: GabColors.secondary,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Taux par défaut ${insurer.name} : '
                        '${(insurer.defaultRate * 100).round()} % du prix, '
                        'à titre informatif.',
                        style: const TextStyle(
                            color: GabColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Dérogations par catégorie',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: GabColors.muted,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            for (final exception in insurer.exceptions)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(color: GabColors.muted)),
                    Expanded(
                      child: Text(exception,
                          style: const TextStyle(
                              color: GabColors.muted, fontSize: 13)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

enum _NotifCategory { orders, security, offers }

enum _NotifTarget { orderDelivering, orderDelivered, security, none }

class _NotificationItem {
  _NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.dayGroup,
    required this.category,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.target,
    this.promo = false,
    this.actionLabel,
    this.unread = false,
  });

  final String title;
  final String body;
  final String time;
  final String dayGroup;
  final _NotifCategory category;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final _NotifTarget target;
  final bool promo;
  final String? actionLabel;
  bool unread;
}

List<_NotificationItem> _buildDemoNotifications() => [
      _NotificationItem(
        title: 'Commande en route',
        body: 'Votre commande #GP-2607-4190 a été récupérée par le '
            'livreur. Livraison estimée à 15:50.',
        time: "Aujourd'hui, 10:30",
        dayGroup: "Aujourd'hui",
        category: _NotifCategory.orders,
        icon: Icons.inventory_2,
        iconBackground: const Color(0xFFA8F4B9),
        iconColor: const Color(0xFF00210D),
        target: _NotifTarget.orderDelivering,
        actionLabel: 'Suivre mon colis',
        unread: true,
      ),
      _NotificationItem(
        title: 'Nouvelle connexion',
        body: "Un nouvel appareil s'est connecté à votre compte "
            "Gab'Pharma depuis Libreville, Gabon.",
        time: "Aujourd'hui, 08:15",
        dayGroup: "Aujourd'hui",
        category: _NotifCategory.security,
        icon: Icons.shield,
        iconBackground: const Color(0xFFFFDAD6),
        iconColor: const Color(0xFF93000A),
        target: _NotifTarget.security,
      ),
      _NotificationItem(
        title: 'Commande livrée',
        body: 'La commande #GP-2606-3980 a été livrée avec succès à '
            'Pharmacie du Centre.',
        time: 'Hier, 16:45',
        dayGroup: 'Hier',
        category: _NotifCategory.orders,
        icon: Icons.check_circle,
        iconBackground: GabColors.softGreen,
        iconColor: GabColors.secondary,
        target: _NotifTarget.orderDelivered,
      ),
      _NotificationItem(
        title: 'Promotion Flash !',
        body: 'Profitez de -15% sur tous les produits de parapharmacie '
            'ce weekend. Code : GABPHARMA15',
        time: 'Hier',
        dayGroup: 'Hier',
        category: _NotifCategory.offers,
        icon: Icons.local_offer,
        iconBackground: Colors.white,
        iconColor: GabColors.primary,
        target: _NotifTarget.none,
        promo: true,
      ),
      _NotificationItem(
        title: 'Stock faible',
        body: 'Attention, votre produit habituel "Paracétamol 500mg" '
            'est bientôt en rupture de stock.',
        time: 'Hier',
        dayGroup: 'Hier',
        category: _NotifCategory.orders,
        icon: Icons.inventory_2_outlined,
        iconBackground: const Color(0xFFFFDEA7),
        iconColor: const Color(0xFF5E4200),
        target: _NotifTarget.none,
      ),
    ];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _items = _buildDemoNotifications();
  _NotifCategory? _filter;

  void _openNotification(_NotificationItem item) {
    setState(() => item.unread = false);
    switch (item.target) {
      case _NotifTarget.orderDelivering:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const DeliveryTrackingScreen(reference: 'GP-2607-4190'),
          ),
        );
      case _NotifTarget.orderDelivered:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OrderDetailScreen(reference: 'GP-2606-3980'),
          ),
        );
      case _NotifTarget.security:
        Navigator.pushNamed(context, '/security');
      case _NotifTarget.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filter == null
        ? _items
        : _items.where((n) => n.category == _filter).toList();
    final groups = <String>[];
    for (final item in visible) {
      if (!groups.contains(item.dayGroup)) groups.add(item.dayGroup);
    }
    return Scaffold(
      backgroundColor: GabColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
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
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _NotifFilterChip(
                  label: 'Tout',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                _NotifFilterChip(
                  label: 'Commandes',
                  selected: _filter == _NotifCategory.orders,
                  onTap: () => setState(() => _filter = _NotifCategory.orders),
                ),
                const SizedBox(width: 8),
                _NotifFilterChip(
                  label: 'Sécurité',
                  selected: _filter == _NotifCategory.security,
                  onTap: () =>
                      setState(() => _filter = _NotifCategory.security),
                ),
                const SizedBox(width: 8),
                _NotifFilterChip(
                  label: 'Offres',
                  selected: _filter == _NotifCategory.offers,
                  onTap: () => setState(() => _filter = _NotifCategory.offers),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Aucune notification',
                message: 'Nous vous tiendrons informé des mises à jour '
                    'importantes de vos commandes.',
              ),
            )
          else
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  group,
                  style: const TextStyle(
                      color: GabColors.muted, fontWeight: FontWeight.w700),
                ),
              ),
              for (final item in visible.where((n) => n.dayGroup == group))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NotificationCard(
                    item: item,
                    onTap: () => _openNotification(item),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}

class _NotifFilterChip extends StatelessWidget {
  const _NotifFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? GabColors.primary : GabColors.softGreen,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : GabColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: item.promo ? GabColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: item.promo
                  ? null
                  : Border.all(color: GabColors.outlineVariant),
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.iconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: item.promo
                                        ? Colors.white
                                        : GabColors.ink,
                                  ),
                                ),
                              ),
                              Text(
                                item.time.contains(',')
                                    ? item.time.split(', ').last
                                    : item.time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: item.promo
                                      ? Colors.white70
                                      : GabColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: item.promo
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : GabColors.muted,
                            ),
                          ),
                          if (item.actionLabel != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.actionLabel!,
                                  style: const TextStyle(
                                    color: GabColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward,
                                    size: 14, color: GabColors.primary),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.unread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: GabColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

enum _HelpCategory { medications, delivery, payments, account }

extension on _HelpCategory {
  String get label => switch (this) {
        _HelpCategory.medications => 'Médicaments',
        _HelpCategory.delivery => 'Livraison',
        _HelpCategory.payments => 'Paiements',
        _HelpCategory.account => 'Compte',
      };

  String get hint => switch (this) {
        _HelpCategory.medications => 'Disponibilité, posologie',
        _HelpCategory.delivery => 'Suivi, délais',
        _HelpCategory.payments => 'Facturation, Airtel',
        _HelpCategory.account => 'Sécurité, profil',
      };

  IconData get icon => switch (this) {
        _HelpCategory.medications => Icons.medication,
        _HelpCategory.delivery => Icons.local_shipping,
        _HelpCategory.payments => Icons.payments,
        _HelpCategory.account => Icons.shield,
      };

  Color get background => switch (this) {
        _HelpCategory.medications => GabColors.primary,
        _HelpCategory.delivery => const Color(0xFFA8F4B9),
        _HelpCategory.payments => const Color(0xFFFFDEA7),
        _HelpCategory.account => const Color(0xFFD7E6DE),
      };

  Color get foreground => switch (this) {
        _HelpCategory.medications => Colors.white,
        _HelpCategory.delivery => const Color(0xFF00210D),
        _HelpCategory.payments => const Color(0xFF5E4200),
        _HelpCategory.account => const Color(0xFF3F4940),
      };
}

class _FaqEntry {
  const _FaqEntry(
      {required this.question, required this.answer, required this.category});

  final String question;
  final String answer;
  final _HelpCategory category;
}

const _faqEntries = <_FaqEntry>[
  _FaqEntry(
    question: 'Quels sont les délais de livraison à Libreville ?',
    answer: 'Les livraisons dans le Grand Libreville s\'effectuent '
        'généralement entre 1h et 3h après la validation de votre '
        'commande.',
    category: _HelpCategory.delivery,
  ),
  _FaqEntry(
    question: 'Acceptez-vous Airtel Money ?',
    answer: 'Oui, nous acceptons Airtel Money et Moov Money pour tous '
        'les règlements instantanés.',
    category: _HelpCategory.payments,
  ),
  _FaqEntry(
    question: "Comment vérifier la disponibilité d'un médicament ?",
    answer: 'Utilisez la recherche pour voir le stock en temps réel par '
        'pharmacie avant de commander.',
    category: _HelpCategory.medications,
  ),
  _FaqEntry(
    question: 'Puis-je changer la posologie indiquée par le pharmacien ?',
    answer: 'Non, seul un professionnel de santé peut modifier une '
        'posologie. Contactez votre pharmacien ou votre médecin.',
    category: _HelpCategory.medications,
  ),
  _FaqEntry(
    question: 'Comment modifier mon numéro ou mon mot de passe ?',
    answer: 'Rendez-vous dans Profil puis Sécurité et paramètres pour '
        'mettre à jour vos identifiants.',
    category: _HelpCategory.account,
  ),
  _FaqEntry(
    question: 'Que faire si mon paiement échoue ?',
    answer: 'Vérifiez votre solde Mobile Money puis reprenez le '
        'paiement depuis Paiements et remboursements.',
    category: _HelpCategory.payments,
  ),
];

enum _TicketStatus { open, resolved }

enum _TicketPriority { low, normal, high }

extension on _TicketPriority {
  String get label => switch (this) {
        _TicketPriority.low => 'Basse',
        _TicketPriority.normal => 'Normale',
        _TicketPriority.high => 'Haute',
      };

  Color get color => switch (this) {
        _TicketPriority.low => GabColors.muted,
        _TicketPriority.normal => GabColors.secondary,
        _TicketPriority.high => GabColors.danger,
      };
}

class _SupportTicket {
  _SupportTicket({
    required this.reference,
    required this.subject,
    required this.status,
    required this.priority,
    required this.lastActivity,
    this.linkedOrder,
  });

  final String reference;
  final String subject;
  _TicketStatus status;
  final _TicketPriority priority;
  final String lastActivity;
  final String? linkedOrder;
}

List<_SupportTicket> _buildDemoTickets() => [
      _SupportTicket(
        reference: 'TK-45920',
        subject: 'Retard de livraison - Akanda',
        status: _TicketStatus.open,
        priority: _TicketPriority.high,
        lastActivity: 'Mis à jour il y a 2h',
        linkedOrder: 'GP-2607-4190',
      ),
      _SupportTicket(
        reference: 'TK-45812',
        subject: 'Erreur de dosage - Paracétamol',
        status: _TicketStatus.resolved,
        priority: _TicketPriority.normal,
        lastActivity: 'Le 12 mai 2026',
        linkedOrder: 'GP-2606-3980',
      ),
    ];

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  _HelpCategory? _category;
  final _tickets = _buildDemoTickets();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqEntry> get _visibleFaq {
    final query = _searchController.text.trim().toLowerCase();
    return _faqEntries.where((faq) {
      final matchesCategory = _category == null || faq.category == _category;
      final matchesQuery = query.isEmpty ||
          faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _openTicketForm() async {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String? linkedOrder;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Créer une demande',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                const Text('Sujet',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    hintText: 'Ex : Retard de livraison',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Message',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Décrivez votre problème...',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Commande liée (optionnel)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: linkedOrder,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Aucune commande liée')),
                    for (final ref in _orderDetails.keys)
                      DropdownMenuItem(value: ref, child: Text('#$ref')),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => linkedOrder = value),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pièce jointe indisponible en démonstration.',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Ajouter une pièce jointe'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (subjectController.text.trim().isEmpty ||
                          messageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Indiquez un sujet et un message.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, true);
                    },
                    child: const Text('Envoyer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (created ?? false) {
      final subject = subjectController.text.trim();
      final message = messageController.text.trim();
      setState(() {
        _tickets.insert(
          0,
          _SupportTicket(
            reference: 'TK-${46000 + _tickets.length}',
            subject: subject,
            status: _TicketStatus.open,
            priority: _TicketPriority.normal,
            lastActivity: "À l'instant",
            linkedOrder: linkedOrder,
          ),
        );
      });
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            initialSubject: subject,
            initialMessage: message,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        floatingActionButton: FloatingActionButton(
          onPressed: _openTicketForm,
          backgroundColor: GabColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_comment, color: Colors.white),
        ),
        appBar: AppBar(
          title: const Text("Centre d'aide"),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Comment pouvons-nous vous aider ?',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Catégories',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (_category != null)
                  TextButton(
                    onPressed: () => setState(() => _category = null),
                    child: const Text('Voir tout'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 128,
              ),
              children: [
                for (final category in _HelpCategory.values)
                  _CategoryTile(
                    category: category,
                    selected: _category == category,
                    onTap: () => setState(
                      () => _category = _category == category ? null : category,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('FAQ Populaires',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (_visibleFaq.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Aucun résultat pour cette recherche.',
                  style: TextStyle(color: GabColors.muted),
                ),
              )
            else
              for (final faq in _visibleFaq)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FaqTile(faq: faq),
                ),
            const SizedBox(height: 24),
            const Text('Mes tickets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final ticket in _tickets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TicketTile(
                  ticket: ticket,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(
                        ticketReference: ticket.reference,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _HelpCategory category;
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? GabColors.primary : GabColors.outlineVariant,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: category.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(category.icon, color: category.foreground, size: 18),
                ),
                const SizedBox(height: 8),
                Text(category.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(category.hint,
                    style:
                        const TextStyle(color: GabColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ),
      );
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.faq});

  final _FaqEntry faq;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GabColors.outlineVariant),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.faq.question,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: GabColors.muted,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.faq.answer,
                      style: const TextStyle(
                          color: GabColors.muted, fontSize: 13)),
                ),
              ),
          ],
        ),
      );
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket, required this.onTap});

  final _SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolved = ticket.status == _TicketStatus.resolved;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: resolved ? 0.8 : 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GabColors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('#${ticket.reference}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: resolved
                                  ? GabColors.outlineVariant
                                      .withValues(alpha: 0.4)
                                  : const Color(0xFF9DF6B2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              child: Text(
                                resolved ? 'RÉSOLU' : 'OUVERT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: resolved
                                      ? GabColors.muted
                                      : const Color(0xFF00210D),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color:
                                  ticket.priority.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              child: Text(
                                ticket.priority.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: ticket.priority.color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(ticket.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: GabColors.muted)),
                      Text(ticket.lastActivity,
                          style: const TextStyle(
                              color: GabColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: GabColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ChatKind { patientText, agentText, systemInfo, agentProduct }

class _ChatMessage {
  _ChatMessage.patient(this.text, this.time)
      : kind = _ChatKind.patientText,
        productName = null,
        productPrice = null;

  _ChatMessage.agent(this.text, this.time)
      : kind = _ChatKind.agentText,
        productName = null,
        productPrice = null;

  _ChatMessage.info(this.text)
      : kind = _ChatKind.systemInfo,
        time = '',
        productName = null,
        productPrice = null;

  _ChatMessage.product(this.productName, this.productPrice, this.time)
      : kind = _ChatKind.agentProduct,
        text = '';

  final _ChatKind kind;
  final String text;
  final String time;
  final String? productName;
  final int? productPrice;
}

class _SupportThread {
  _SupportThread({
    required this.agentName,
    required this.agentSubtitle,
    required this.status,
    required this.messages,
  });

  final String agentName;
  final String agentSubtitle;
  _TicketStatus status;
  final List<_ChatMessage> messages;
}

final Map<String, _SupportThread Function()> _supportThreadBuilders = {
  'TK-45920': () => _SupportThread(
        agentName: 'Support Livraison',
        agentSubtitle: 'En ligne • Paul K.',
        status: _TicketStatus.open,
        messages: [
          _ChatMessage.agent(
            'Bonjour ! Je vois que votre commande #GP-2607-4190 est en '
                'cours de livraison. Comment puis-je vous aider ?',
            '15:52',
          ),
          _ChatMessage.patient(
            'Bonjour, la livraison devait arriver à 15:50 mais je n\'ai '
                'encore rien reçu.',
            '15:58',
          ),
          _ChatMessage.agent(
            'Je suis désolé pour ce retard. Je vérifie avec le livreur '
                'Jean M. tout de suite.',
            '16:00',
          ),
          _ChatMessage.agent(
            'Le livreur signale un trafic dense sur la route d\'Akanda. '
                'Nouvelle heure d\'arrivée estimée : 16:20.',
            '16:02',
          ),
        ],
      ),
  'TK-45812': () => _SupportThread(
        agentName: 'Support Pharmacie',
        agentSubtitle: 'Dr. Mireille',
        status: _TicketStatus.resolved,
        messages: [
          _ChatMessage.patient(
            'Bonjour, je pense qu\'il y a une erreur sur la posologie '
                'indiquée pour le Paracétamol 500mg de ma dernière commande.',
            '09:15',
          ),
          _ChatMessage.agent(
            'Bonjour ! Merci de votre signalement. Pouvez-vous me '
                'préciser la posologie indiquée sur l\'étiquette ?',
            '09:17',
          ),
          _ChatMessage.patient(
            'Il est indiqué 3 comprimés toutes les 4 heures, ce qui me '
                'semble élevé.',
            '09:19',
          ),
          _ChatMessage.info(
            'Cette conversation est sécurisée par Gab\'Pharma. Vos '
            'données médicales restent confidentielles.',
          ),
          _ChatMessage.agent(
            'Vous avez raison, c\'est une erreur d\'étiquetage. La '
                'posologie correcte est 1 à 2 comprimés toutes les 6 heures, '
                'sans dépasser 8 comprimés par jour. Nous corrigeons la '
                'fiche produit.',
            '09:24',
          ),
          _ChatMessage.agent(
            'Ticket marqué comme résolu. N\'hésitez pas si vous avez '
                "d'autres questions.",
            '09:25',
          ),
        ],
      ),
};

_SupportThread _defaultSupportThread() => _SupportThread(
      agentName: 'Support Pharmacie',
      agentSubtitle: 'En ligne • Dr. Mireille',
      status: _TicketStatus.open,
      messages: [
        _ChatMessage.agent(
          'Bonjour ! Comment puis-je vous aider avec votre ordonnance '
              "aujourd'hui ?",
          '09:15',
        ),
        _ChatMessage.patient(
          'Bonjour. Je voulais savoir si le médicament "Dolirhume" est '
              'disponible à la pharmacie du centre-ville ?',
          '09:17',
        ),
        _ChatMessage.info(
          'Cette conversation est sécurisée par Gab\'Pharma. Vos '
          'données médicales restent confidentielles.',
        ),
        _ChatMessage.agent(
          'Oui, nous en avons encore en stock. Souhaitez-vous que je '
              'vous mette une boîte de côté pour votre passage ?',
          '09:20',
        ),
        _ChatMessage.product('Dolirhume Paracétamol', 2500, '09:21'),
        _ChatMessage.agent(
          'Ticket créé et transmis à notre équipe. Nous vous répondrons '
              'sous peu.',
          '09:23',
        ),
      ],
    );

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    this.ticketReference,
    this.initialSubject,
    this.initialMessage,
    super.key,
  });

  final String? ticketReference;
  final String? initialSubject;
  final String? initialMessage;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final _SupportThread _thread;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final builder = widget.ticketReference == null
        ? null
        : _supportThreadBuilders[widget.ticketReference];
    if (builder != null) {
      _thread = builder();
    } else if (widget.initialMessage != null) {
      _thread = _SupportThread(
        agentName: "Support Gab'Pharma",
        agentSubtitle: 'Équipe support',
        status: _TicketStatus.open,
        messages: [
          _ChatMessage.patient(widget.initialMessage!, _now()),
          _ChatMessage.info(
            'Cette conversation est sécurisée par Gab\'Pharma. Vos '
            'données médicales restent confidentielles.',
          ),
          _ChatMessage.agent(
            'Merci, votre demande a bien été transmise à notre équipe '
            'support. Nous vous répondrons sous peu.',
            _now(),
          ),
        ],
      );
    } else {
      _thread = _defaultSupportThread();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _now() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final reopened = _thread.status == _TicketStatus.resolved;
    setState(() {
      _thread.messages.add(_ChatMessage.patient(text, _now()));
      if (reopened) _thread.status = _TicketStatus.open;
    });
    _inputController.clear();
    if (reopened) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ticket rouvert — votre message a été envoyé.'),
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: GabColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.support_agent, color: GabColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _thread.agentName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _thread.agentSubtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: GabColors.secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Appel avec le support indisponible en démonstration.'),
                ),
              ),
              icon: const Icon(Icons.call),
            ),
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
        body: Column(
          children: [
            if (_thread.status == _TicketStatus.resolved)
              Container(
                width: double.infinity,
                color: GabColors.softGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: const Text(
                  'Ticket résolu — envoyez un message pour le rouvrir.',
                  style: TextStyle(
                      color: GabColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: GabColors.softGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          "Aujourd'hui",
                          style:
                              TextStyle(fontSize: 11, color: GabColors.muted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final message in _thread.messages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ChatBubble(message: message),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pièces jointes indisponibles en démonstration.',
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline,
                          color: GabColors.primary),
                    ),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: GabColors.outlineVariant),
                        ),
                        child: TextField(
                          controller: _inputController,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Votre message...',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: GabColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.kind == _ChatKind.systemInfo) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GabColors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: GabColors.secondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message.text,
                  style: const TextStyle(color: GabColors.muted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (message.kind == _ChatKind.agentProduct) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18).copyWith(
                    topLeft: const Radius.circular(4),
                  ),
                  border: Border.all(color: GabColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: GabColors.softGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medication,
                          color: GabColors.primary, size: 32),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message.productName ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(
                            '${message.productPrice} FCFA'.replaceAllMapped(
                                RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                (m) => '${m[1]} '),
                            style: const TextStyle(
                                color: GabColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/medication'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Voir le produit',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(message.time,
                    style:
                        const TextStyle(color: GabColors.muted, fontSize: 11)),
              ),
            ],
          ),
        ),
      );
    }
    final isPatient = message.kind == _ChatKind.patientText;
    return Align(
      alignment: isPatient ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isPatient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isPatient ? GabColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isPatient ? 18 : 4),
                  bottomRight: Radius.circular(isPatient ? 4 : 18),
                ),
                border: isPatient
                    ? null
                    : Border.all(color: GabColors.outlineVariant),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isPatient ? Colors.white : GabColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.time,
                    style:
                        const TextStyle(color: GabColors.muted, fontSize: 11)),
                if (isPatient) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all,
                      size: 13, color: GabColors.primary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometrics = true;
  bool _orderNotifs = true;
  bool _promoNotifs = false;
  bool _securityNotifs = true;

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    var obscure = true;

    bool hasMinLength(String v) => v.length >= 8;
    bool hasUpperAndDigit(String v) =>
        RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[0-9]').hasMatch(v);
    bool hasSpecialChar(String v) =>
        RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-]''').hasMatch(v);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Changer le mot de passe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentController,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe actuel',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newController,
                  obscureText: obscure,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
                const SizedBox(height: 8),
                _RuleRow(
                    label: 'Au moins 8 caractères',
                    ok: hasMinLength(newController.text)),
                _RuleRow(
                    label: 'Une majuscule et un chiffre',
                    ok: hasUpperAndDigit(newController.text)),
                _RuleRow(
                    label: 'Un caractère spécial',
                    ok: hasSpecialChar(newController.text)),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  obscureText: obscure,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
                CheckboxListTile(
                  value: !obscure,
                  onChanged: (v) =>
                      setSheetState(() => obscure = !(v ?? false)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Afficher les mots de passe'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final newPwd = newController.text;
                      if (currentController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Indiquez votre mot de passe actuel.'),
                          ),
                        );
                        return;
                      }
                      if (!hasMinLength(newPwd) ||
                          !hasUpperAndDigit(newPwd) ||
                          !hasSpecialChar(newPwd)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Le nouveau mot de passe ne respecte pas '
                              'les règles ci-dessus.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (newPwd != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La confirmation ne correspond pas au '
                              'nouveau mot de passe.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, true);
                    },
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    if ((saved ?? false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mot de passe mis à jour.'),
      ));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez vous reconnecter avec votre identifiant et le '
          'code de vérification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: GabColors.danger),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await AuthSession.instance.clear();
    }
    if ((confirmed ?? false) && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        appBar: AppBar(title: const Text('Sécurité')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GabColors.softGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: GabColors.primary,
                    child: Text('GN',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Grâce Nziengui',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('Libreville, Gabon',
                          style: TextStyle(color: GabColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: 'Sécurité du compte',
              children: [
                _SettingsRow(
                  icon: Icons.lock_outline,
                  label: 'Changer le mot de passe',
                  onTap: _changePassword,
                ),
                _SettingsToggleRow(
                  icon: Icons.fingerprint,
                  label: 'Touch ID / Face ID',
                  subtitle: 'Sera activé une fois le capteur biométrique '
                      "connecté à l'application.",
                  value: _biometrics,
                  onChanged: (v) => setState(() => _biometrics = v),
                ),
                _SettingsRow(
                  icon: Icons.smartphone,
                  label: 'Session active',
                  subtitle: 'Cet appareil • Connecté maintenant',
                  onTap: null,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    "L'authentification à deux facteurs (2FA) est "
                    'obligatoire et ne peut pas être désactivée.',
                    style: TextStyle(color: GabColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Légal et confidentialité',
              children: [
                _SettingsRow(
                  icon: Icons.shield_outlined,
                  label: 'Politique de confidentialité',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),
                _SettingsRow(
                  icon: Icons.gavel_outlined,
                  label: 'Conditions générales',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Préférences de notifications',
              children: [
                _SettingsToggleRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Commandes et livraison',
                  value: _orderNotifs,
                  onChanged: (v) => setState(() => _orderNotifs = v),
                ),
                _SettingsToggleRow(
                  icon: Icons.local_offer_outlined,
                  label: 'Offres et promotions',
                  value: _promoNotifs,
                  onChanged: (v) => setState(() => _promoNotifs = v),
                ),
                _SettingsToggleRow(
                  icon: Icons.security,
                  label: 'Alertes de sécurité',
                  value: _securityNotifs,
                  onChanged: (v) => setState(() => _securityNotifs = v),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: GabColors.danger,
                  side: const BorderSide(color: GabColors.danger),
                  backgroundColor: const Color(0xFFFFDAD6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Version 2.4.1 (Build 108)',
                style: TextStyle(color: GabColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      );
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16, color: ok ? GabColors.primary : GabColors.muted),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: ok ? GabColors.primary : GabColors.muted)),
          ],
        ),
      );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: GabColors.secondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GabColors.softGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: GabColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 15)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: const TextStyle(
                              color: GabColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: GabColors.muted),
            ],
          ),
        ),
      );
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GabColors.softGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: GabColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            color: GabColors.muted, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: GabColors.primary,
            ),
          ],
        ),
      );
}

class _PharmacyProduct {
  const _PharmacyProduct({
    required this.stockId,
    required this.category,
    required this.name,
    required this.details,
    required this.price,
  });

  final int stockId;
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
  int? _pharmacyId;
  PharmacyDetail? _pharmacy;
  List<_PharmacyProduct> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pharmacyId == null) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      _pharmacyId = arg is int ? arg : null;
      _load();
    }
  }

  Future<void> _load() async {
    final pharmacyId = _pharmacyId;
    if (pharmacyId == null) {
      setState(() {
        _loading = false;
        _error = 'Pharmacie introuvable.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pharmacy = await fetchPharmacyDetail(pharmacyId);
      final page = await fetchPharmacyCatalog(pharmacyId);
      if (!mounted) return;
      setState(() {
        _pharmacy = pharmacy;
        _products = page.results
            .map((stock) => _PharmacyProduct(
                  stockId: stock.id,
                  category: stock.medication.dci.isNotEmpty
                      ? stock.medication.dci
                      : stock.medication.name,
                  name: stock.medication.name,
                  details: [
                    if (stock.medication.dosage.isNotEmpty)
                      stock.medication.dosage,
                    if (stock.medication.formLabel.isNotEmpty)
                      stock.medication.formLabel,
                  ].join(' • '),
                  price: stock.priceFcfa,
                ))
            .toList();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Impossible de joindre l'API Gab'Pharma.";
      });
    }
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

  void _showNotConnected(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildTopBar(BuildContext context) => SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: GabColors.primary),
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
              icon: const Icon(Icons.share_outlined, color: GabColors.primary),
            ),
            IconButton(
              onPressed: () => _showNotConnected(
                  'Les pharmacies ne peuvent pas être mises en favori.'),
              icon: const Icon(Icons.favorite_border,
                  color: GabColors.primary),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pharmacy = _pharmacy;
    return Scaffold(
      backgroundColor: GabColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            const Divider(height: 1, color: GabColors.outlineVariant),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null || pharmacy == null)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off,
                                    size: 52, color: GabColors.secondary),
                                const SizedBox(height: 16),
                                Text(_error ?? 'Pharmacie introuvable.',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton(
                                    onPressed: _load,
                                    child: const Text('Réessayer')),
                              ],
                            ),
                          ),
                        )
                      : _buildBody(context, pharmacy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PharmacyDetail pharmacy) {
    final serviceChips = [
      for (final service in pharmacy.services)
        _ServiceChip(icon: Icons.check_circle_outline, label: service.label),
      if (pharmacy.acceptsCashOnDelivery)
        const _ServiceChip(
          icon: Icons.payments_outlined,
          label: 'Paiement à la livraison',
        ),
      if (pharmacy.acceptedPlanCount > 0)
        _ServiceChip(
          icon: Icons.verified_outlined,
          label: pharmacy.acceptedPlanCount > 1
              ? '${pharmacy.acceptedPlanCount} assurances acceptées'
              : '${pharmacy.acceptedPlanCount} assurance acceptée',
          accent: true,
        ),
    ];
    final scheduleValue = pharmacy.is24h
        ? 'Ouvert tous les jours, 24h/24.'
        : pharmacy.isOpenNow
            ? 'Actuellement ouverte.'
            : 'Actuellement fermée.';
    return ListView(
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
                child: Icon(Icons.storefront, color: Colors.white, size: 56),
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
                    if (pharmacy.isOnDuty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
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
                    Text(
                      pharmacy.name,
                      style: const TextStyle(
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
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      title: 'Adresse',
                      value: pharmacy.address.isNotEmpty
                          ? '${pharmacy.address}, ${pharmacy.zoneLabel}'
                          : '${pharmacy.zoneLabel} (adresse non renseignée)',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.call_outlined,
                      title: 'Contact',
                      value: pharmacy.phone.isNotEmpty
                          ? pharmacy.phone
                          : 'Non renseigné',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      title: 'Horaires',
                      value: scheduleValue,
                      trailing: Text(
                        pharmacy.is24h
                            ? 'Ouvert 24h/24'
                            : pharmacy.isOpenNow
                                ? 'Ouvert'
                                : 'Fermé',
                        style: TextStyle(
                          color: pharmacy.is24h || pharmacy.isOpenNow
                              ? GabColors.primary
                              : GabColors.muted,
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
                          onPressed: () => _showNotConnected(
                              'Navigation indisponible en démonstration.'),
                          icon: const Icon(Icons.directions,
                              color: GabColors.primary),
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
              if (serviceChips.isEmpty)
                const Text('Aucun service renseigné pour cette pharmacie.',
                    style: TextStyle(color: GabColors.muted))
              else
                Wrap(spacing: 8, runSpacing: 8, children: serviceChips),
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
                        style: TextStyle(color: GabColors.muted)),
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
        if (_products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Aucun produit en stock actuellement.',
                style: TextStyle(color: GabColors.muted)),
          )
        else
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
                  onPressed: () => _showNotConnected(
                      pharmacy.phone.isNotEmpty
                          ? 'Appel vers ${pharmacy.phone} — composition indisponible en démonstration.'
                          : 'Numéro de téléphone non renseigné pour cette pharmacie.'),
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
    );
  }
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
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
          onTap: () => Navigator.pushNamed(context, '/medication',
              arguments: product.stockId),
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
                  style: const TextStyle(color: GabColors.muted, fontSize: 12),
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
                      onTap: () =>
                          addToCartWithFeedback(context, product.stockId),
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

enum _StockStatus { inStock, lowStock }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

enum _FavoritesSort { recent, name, price }

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _queryController = TextEditingController();
  _FavoritesSort _sort = _FavoritesSort.recent;
  List<PatientFavorite> _favorites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final favorites = await fetchFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Impossible de joindre l'API Gab'Pharma.";
      });
    }
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

  List<PatientFavorite> get _visibleItems {
    final query = _queryController.text.trim().toLowerCase();
    final list = query.isEmpty
        ? [..._favorites]
        : _favorites
            .where((item) => item.medication.name.toLowerCase().contains(query))
            .toList();
    switch (_sort) {
      case _FavoritesSort.name:
        list.sort((a, b) => a.medication.name.compareTo(b.medication.name));
      case _FavoritesSort.price:
        list.sort((a, b) =>
            (a.bestPriceFcfa ?? 1 << 30).compareTo(b.bestPriceFcfa ?? 1 << 30));
      case _FavoritesSort.recent:
        break;
    }
    return list;
  }

  void _removeItem(PatientFavorite favorite) {
    final index = _favorites.indexOf(favorite);
    setState(() => _favorites.remove(favorite));
    removeFavorite(favorite.id).catchError((_) {
      if (mounted) {
        setState(
            () => _favorites.insert(index.clamp(0, _favorites.length), favorite));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${favorite.medication.name} retiré des favoris.'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () async {
            try {
              final restored =
                  await addFavorite(favorite.medication.medicationId);
              if (!mounted) return;
              setState(() =>
                  _favorites.insert(index.clamp(0, _favorites.length), restored));
            } on Object {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Impossible de restaurer ce favori.')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _openMedication(PatientFavorite favorite) async {
    final stockId = await findCheapestStockId(favorite.medication.name);
    if (!mounted) return;
    if (stockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Aucune pharmacie ne propose actuellement ${favorite.medication.name}.'),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/medication', arguments: stockId);
  }

  Future<void> _addFavoriteToCart(PatientFavorite favorite) async {
    final stockId = await findCheapestStockId(favorite.medication.name);
    if (!mounted) return;
    if (stockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Aucune pharmacie ne propose actuellement ${favorite.medication.name}.'),
        ),
      );
      return;
    }
    await addToCartWithFeedback(context, stockId);
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
                      icon:
                          const Icon(Icons.more_vert, color: GabColors.primary),
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
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      );

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off,
                  size: 52, color: GabColors.secondary),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    if (_favorites.isEmpty) {
      return _EmptyFavorites(onBrowse: () => Navigator.pop(context));
    }
    return ListView(
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
              favorite: item,
              formatFcfa: _formatFcfa,
              onDelete: () => _removeItem(item),
              onAddToCart: () => _addFavoriteToCart(item),
              onTap: () => _openMedication(item),
            ),
          ),
      ],
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.formatFcfa,
    required this.onDelete,
    required this.onAddToCart,
    required this.onTap,
  });

  final PatientFavorite favorite;
  final String Function(int) formatFcfa;
  final VoidCallback onDelete;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outOfStock = favorite.offerCount == 0;
    final details = [
      if (favorite.medication.dosage.isNotEmpty) favorite.medication.dosage,
      if (favorite.medication.formLabel.isNotEmpty)
        favorite.medication.formLabel,
    ].join(' • ');
    return Opacity(
      opacity: outOfStock ? 0.7 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: outOfStock ? null : onTap,
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
                        color: outOfStock ? GabColors.muted : GabColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(favorite.medication.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          if (details.isNotEmpty)
                            Text(details,
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
                                  formatFcfa(favorite.bestPriceFcfa!),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: GabColors.primary,
                                  ),
                                ),
                                _StockChip(
                                  status: favorite.isLowStock
                                      ? _StockStatus.lowStock
                                      : _StockStatus.inStock,
                                ),
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
                                  disabledBackgroundColor: GabColors.background,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                          side:
                              const BorderSide(color: GabColors.outlineVariant),
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
        color: lowStock ? const Color(0xFFFFDAD6) : const Color(0xFFA8F4B9),
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
              color:
                  lowStock ? const Color(0xFF93000A) : const Color(0xFF287243),
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
