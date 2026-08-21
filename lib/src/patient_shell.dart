import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'auth_screens.dart' show TermsScreen, PrivacyPolicyScreen;
import 'core/api_client.dart' show ApiException;
import 'core/auth_session.dart';
import 'core/patient_catalog.dart';
import 'core/patient_summary.dart';
import 'core/theme.dart';
import 'detail_screens.dart' show OrderDetailScreen;
import 'widgets.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;
  PatientSummary? _summary;
  bool _summaryLoading = true;
  String? _summaryError;
  int? _cartItemsCountOverride;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    cartUpdates.addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    cartUpdates.removeListener(_onCartUpdated);
    super.dispose();
  }

  Future<void> _onCartUpdated() async {
    try {
      final cart = await fetchCart();
      if (!mounted) return;
      setState(() => _cartItemsCountOverride = cart.itemsCount);
    } on Object {
      // Le badge reste simplement inchangé si ce rafraîchissement échoue.
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });
    try {
      final summary = await fetchPatientSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _summaryLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _summaryLoading = false;
        _summaryError = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _summaryLoading = false;
        _summaryError = "Impossible de joindre l'API Gab'Pharma.";
      });
    }
  }

  int get _cartBadgeCount =>
      _cartItemsCountOverride ?? _summary?.cart.itemsCount ?? 0;

  void _switchTab(int index) => setState(() => _index = index);

  List<Widget> get _screens => [
        PatientHomeScreen(
          onSwitchTab: _switchTab,
          summary: _summary,
          loading: _summaryLoading,
          error: _summaryError,
          onRefresh: _loadSummary,
        ),
        SearchScreen(onSwitchTab: _switchTab),
        CartScreen(onSwitchTab: _switchTab),
        OrdersScreen(onSwitchTab: _switchTab),
        ProfileScreen(onSwitchTab: _switchTab),
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
        bottomNavigationBar: MediaQuery(
          // La bottom bar a une hauteur fixe : on fige l'échelle de police
          // système ici pour éviter que les libellés (ex. « Commandes ») ne
          // débordent quand l'utilisateur a agrandi la police de l'appareil.
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Accueil',
              ),
              NavigationDestination(
                  icon: Icon(Icons.search), label: 'Recherche'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: _cartBadgeCount > 0,
                  label: Text('$_cartBadgeCount'),
                  child: const Icon(Icons.shopping_bag_outlined),
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
        ),
      );
}

const _kCategoryPalette = [
  (Color(0xFFFFDEA7), Color(0xFF271900)),
  (Color(0xFFA8F4B9), Color(0xFF00210D)),
  (Color(0xFF9DF6B2), Color(0xFF00210C)),
  (Color(0xFFBFE3FF), Color(0xFF001D33)),
  (Color(0xFFFFD6D6), Color(0xFF3A0A0A)),
];

const _kPharmacyGradientPalette = [
  [Color(0xFF0B7A3E), Color(0xFF39B27A)],
  [Color(0xFF206B3D), Color(0xFF8CD79F)],
  [Color(0xFF0E5C8A), Color(0xFF4FB3E8)],
];

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({
    required this.onSwitchTab,
    required this.summary,
    required this.loading,
    required this.error,
    required this.onRefresh,
    super.key,
  });

  final ValueChanged<int> onSwitchTab;
  final PatientSummary? summary;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

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
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            PatientTopBar(onSwitchTab: onSwitchTab),
            Expanded(child: _buildBody(context)),
          ],
        ),
      );

  Widget _buildBody(BuildContext context) {
    final summary = this.summary;
    if (summary == null && loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (summary == null && error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off,
                  size: 52, color: GabColors.secondary),
              const SizedBox(height: 16),
              Text('Impossible de charger l\'accueil',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRefresh, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    if (summary == null) return const SizedBox.shrink();

    final pharmacies = <int, PatientPharmacySummary>{};
    for (final stock in summary.featuredStocks) {
      pharmacies.putIfAbsent(stock.pharmacy.id, () => stock.pharmacy);
    }
    final pharmacyList = pharmacies.values.toList();

    final categories = <String>{};
    for (final stock in summary.featuredStocks) {
      if (stock.medication.categoryName.isNotEmpty) {
        categories.add(stock.medication.categoryName);
      }
    }
    final categoryList = categories.toList();

    final displayName = summary.profile.firstName.isNotEmpty
        ? summary.profile.firstName
        : (summary.profile.email.isNotEmpty ? summary.profile.email : '');

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour, $displayName',
                    style: const TextStyle(color: GabColors.muted)),
                const SizedBox(height: 4),
                Text(
                  'Prenez soin de votre santé aujourd’hui',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: GabColors.ink,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  readOnly: true,
                  onTap: () => onSwitchTab(1),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un médicament...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        const Icon(Icons.tune, color: GabColors.primary),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAccess(
                        label: 'Favoris',
                        icon: Icons.favorite,
                        badgeCount: summary.favoriteCount,
                        onTap: () =>
                            Navigator.pushNamed(context, '/favorites'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccess(
                        label: 'Assurance',
                        icon: Icons.verified_user,
                        onTap: () =>
                            Navigator.pushNamed(context, '/insurance'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccess(
                        label: 'Support',
                        icon: Icons.support_agent,
                        badgeCount: summary.supportOpenCount,
                        onTap: () =>
                            Navigator.pushNamed(context, '/support'),
                      ),
                    ),
                  ],
                ),
                if (summary.activeOrder != null) ...[
                  const SizedBox(height: 20),
                  Material(
                    color: GabColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(
                              orderId: summary.activeOrder!.id),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: GabColors.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_shipping,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commande ${summary.activeOrder!.reference}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${summary.activeOrder!.statusLabel} • ${summary.activeOrder!.deliveryModeLabel}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (pharmacyList.isNotEmpty) ...[
                  SectionTitle(
                    'Pharmacies à proximité',
                    action: TextButton(
                      onPressed: () => onSwitchTab(1),
                      child: const Text('Voir tout'),
                    ),
                  ),
                  SizedBox(
                    height: 190,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < pharmacyList.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Builder(builder: (context) {
                            final pharmacy = pharmacyList[i];
                            final String statusLabel;
                            final Color statusColor;
                            if (pharmacy.is24h) {
                              statusLabel = 'Ouvert 24h/24';
                              statusColor = GabColors.primary;
                            } else if (pharmacy.isOnDuty) {
                              statusLabel = 'Ouvert';
                              statusColor = GabColors.secondary;
                            } else {
                              statusLabel = 'Fermé';
                              statusColor = GabColors.muted;
                            }
                            return _PharmacyCard(
                              name: pharmacy.name,
                              zone: pharmacy.zoneLabel,
                              statusLabel: statusLabel,
                              statusColor: statusColor,
                              gradientColors: _kPharmacyGradientPalette[
                                  i % _kPharmacyGradientPalette.length],
                              onTap: () => Navigator.pushNamed(
                                  context, '/pharmacy',
                                  arguments: pharmacy.id),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
                if (summary.featuredStocks.isNotEmpty) ...[
                  SectionTitle(
                    'Médicaments populaires',
                    action: TextButton(
                      onPressed: () => onSwitchTab(1),
                      child: const Text('Parcourir'),
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.58,
                    children: [
                      for (final stock in summary.featuredStocks)
                        _ProductCard(
                          stockId: stock.id,
                          name: stock.medication.name,
                          price: _formatFcfa(stock.priceFcfa),
                          onTap: () => Navigator.pushNamed(
                              context, '/medication',
                              arguments: stock.id),
                        ),
                    ],
                  ),
                ],
                if (categoryList.isNotEmpty) ...[
                  const SectionTitle('Catégories'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < categoryList.length; i++)
                        SizedBox(
                          width:
                              (MediaQuery.of(context).size.width - 52) / 2,
                          height: 90,
                          child: _CategoryTile(
                            label: categoryList[i],
                            icon: Icons.medication_liquid,
                            color: _kCategoryPalette[
                                i % _kCategoryPalette.length].$1,
                            onSurface: _kCategoryPalette[
                                i % _kCategoryPalette.length].$2,
                            compact: true,
                            onTap: () => onSwitchTab(1),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => Material(
        color: GabColors.softGreen,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Badge(
                  isLabelVisible: badgeCount > 0,
                  label: Text('$badgeCount'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA8F4B9),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(icon, color: const Color(0xFF00210D), size: 22),
                  ),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({
    required this.name,
    required this.zone,
    required this.statusLabel,
    required this.statusColor,
    required this.gradientColors,
    required this.onTap,
  });

  final String name;
  final String zone;
  final String statusLabel;
  final Color statusColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 240,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GabColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(Icons.storefront,
                                color: Colors.white, size: 34),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: GabColors.muted),
                      const SizedBox(width: 4),
                      Text(zone,
                          style: const TextStyle(
                              color: GabColors.muted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.stockId,
    required this.name,
    required this.price,
    required this.onTap,
  });

  final int stockId;
  final String name;
  final String price;
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
              border: Border.all(color: GabColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: GabColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication_outlined,
                        color: GabColors.primary, size: 36),
                  ),
                ),
                const SizedBox(height: 8),
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(price,
                    style: const TextStyle(
                        color: GabColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: GabColors.softGreen,
                      foregroundColor: GabColors.primary,
                      minimumSize: const Size.fromHeight(36),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => addToCartWithFeedback(context, stockId),
                    child: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onSurface,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color onSurface;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: compact ? -6 : -2,
                  child: Icon(icon,
                      size: compact ? 48 : 64,
                      color: onSurface.withValues(alpha: 0.2)),
                ),
                Align(
                  alignment: compact ? Alignment.centerLeft : Alignment.topLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 16 : 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SearchResult {
  _SearchResult({
    required this.stockId,
    required this.name,
    required this.details,
    required this.pharmacy,
    required this.price,
    required this.inStock,
  });

  final int stockId;
  final String name;
  final String details;
  final String pharmacy;
  final int price;
  final bool inStock;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.onSwitchTab, super.key});

  final ValueChanged<int> onSwitchTab;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum _SortMode { price, proximity }

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  Timer? _debounce;

  List<PatientCategory> _categories = [];
  List<PatientZone> _zones = [];

  String? _selectedZoneCode;
  int? _selectedCategoryId;
  _SortMode _sort = _SortMode.price;

  List<CatalogStock> _results = [];
  int _resultCount = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadResults();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadResults);
  }

  Future<void> _loadFilters() async {
    try {
      final categories = await fetchPatientCategories();
      final zones = await fetchPatientZones();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _zones = zones;
      });
    } on Object {
      // Filtres indisponibles : les chips resteront simplement vides.
    }
  }

  Future<void> _loadResults() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final page = await fetchCatalog(
        query: _queryController.text.trim(),
        categoryId: _selectedCategoryId,
        zoneCode: _selectedZoneCode,
      );
      if (!mounted) return;
      setState(() {
        _results = page.results;
        _resultCount = page.count;
        _hasMore = page.hasMore;
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await fetchCatalog(
        query: _queryController.text.trim(),
        categoryId: _selectedCategoryId,
        zoneCode: _selectedZoneCode,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _results = [..._results, ...page.results];
        _hasMore = page.hasMore;
        _page += 1;
        _loadingMore = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger la suite des résultats.'),
        ),
      );
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

  List<_SearchResult> get _displayResults {
    final list = _results
        .map((stock) => _SearchResult(
              stockId: stock.id,
              name: stock.medication.name,
              details: [
                if (stock.medication.dosage.isNotEmpty)
                  stock.medication.dosage,
                if (stock.medication.formLabel.isNotEmpty)
                  stock.medication.formLabel,
              ].join(' • '),
              pharmacy: '${stock.pharmacy.name}, ${stock.pharmacy.zoneLabel}',
              price: stock.priceFcfa,
              inStock: stock.inStock,
            ))
        .toList();
    if (_sort == _SortMode.price) {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    return list;
  }

  void _showUnavailableFilter(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtre "$label" pas encore disponible côté API.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickCategory() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune catégorie disponible pour le moment.'),
        ),
      );
      return;
    }
    const clearSentinel = -1;
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Toutes les catégories'),
              trailing: _selectedCategoryId == null
                  ? const Icon(Icons.check, color: GabColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, clearSentinel),
            ),
            for (final category in _categories)
              ListTile(
                title: Text(category.name),
                trailing: _selectedCategoryId == category.id
                    ? const Icon(Icons.check, color: GabColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, category.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(
      () => _selectedCategoryId = selected == clearSentinel ? null : selected,
    );
    _loadResults();
  }

  String? get _selectedCategoryName {
    if (_selectedCategoryId == null) return null;
    for (final category in _categories) {
      if (category.id == _selectedCategoryId) return category.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            PatientTopBar(onSwitchTab: widget.onSwitchTab),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un médicament...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _queryController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final zone in _zones) ...[
                          _FilterChipPill(
                            label: zone.label,
                            selected: _selectedZoneCode == zone.code,
                            onTap: () {
                              setState(() => _selectedZoneCode =
                                  _selectedZoneCode == zone.code
                                      ? null
                                      : zone.code);
                              _loadResults();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        _FilterChipPill(
                          label: _selectedCategoryName ?? 'Catégorie',
                          selected: _selectedCategoryId != null,
                          trailingIcon: Icons.filter_list,
                          onTap: _pickCategory,
                        ),
                        const SizedBox(width: 8),
                        _FilterChipPill(
                          label: 'Forme',
                          onTap: () => _showUnavailableFilter('Forme'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Résultats ($_resultCount)',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _sort = _SortMode.price),
                        icon: const Icon(Icons.swap_vert, size: 18),
                        label: const Text('Prix'),
                        style: TextButton.styleFrom(
                          foregroundColor: _sort == _SortMode.price
                              ? GabColors.primary
                              : GabColors.muted,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _sort = _SortMode.proximity);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Le tri par proximité nécessite la géolocalisation (à venir).'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.near_me, size: 18),
                        label: const Text('Proximité'),
                        style: TextButton.styleFrom(
                          foregroundColor: _sort == _SortMode.proximity
                              ? GabColors.primary
                              : GabColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off,
                              size: 44, color: GabColors.secondary),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loadResults,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  else if (_displayResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: 'Aucun résultat',
                        message:
                            'Essayez un autre médicament, une autre zone ou une autre catégorie.',
                      ),
                    )
                  else ...[
                    for (final result in _displayResults)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SearchResultCard(
                          result: result,
                          formatFcfa: _formatFcfa,
                          onTap: () => Navigator.pushNamed(
                              context, '/medication',
                              arguments: result.stockId),
                        ),
                      ),
                    if (_hasMore)
                      Center(
                        child: _loadingMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: CircularProgressIndicator(),
                              )
                            : TextButton(
                                onPressed: _loadMore,
                                child: const Text('Charger plus'),
                              ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? GabColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border:
                  selected ? null : Border.all(color: GabColors.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : GabColors.muted,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  Icon(trailingIcon,
                      size: 16,
                      color: selected ? Colors.white : GabColors.muted),
                ],
              ],
            ),
          ),
        ),
      );
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
    required this.formatFcfa,
    required this.onTap,
  });

  final _SearchResult result;
  final String Function(int) formatFcfa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: result.inStock ? Colors.white : GabColors.background,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(result.details,
                              style: const TextStyle(color: GabColors.muted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: result.inStock
                            ? const Color(0xFFA8F4B9)
                            : GabColors.softGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            result.inStock
                                ? Icons.check_circle
                                : Icons.cancel_outlined,
                            size: 14,
                            color: result.inStock
                                ? const Color(0xFF287243)
                                : GabColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.inStock ? 'En stock' : 'Épuisé',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: result.inStock
                                  ? const Color(0xFF287243)
                                  : GabColors.muted,
                            ),
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_pharmacy_outlined,
                                  size: 16, color: GabColors.muted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(result.pharmacy,
                                    style: const TextStyle(
                                        color: GabColors.muted,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatFcfa(result.price),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: result.inStock
                                  ? GabColors.primary
                                  : GabColors.muted,
                              decoration: result.inStock
                                  ? TextDecoration.none
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (result.inStock)
                      FilledButton(
                        onPressed: () =>
                            addToCartWithFeedback(context, result.stockId),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Ajouter'),
                      )
                    else
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Alertes de stock pas encore connectées à l\'API.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Alerte'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class CartScreen extends StatefulWidget {
  const CartScreen({required this.onSwitchTab, super.key});

  final ValueChanged<int> onSwitchTab;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PatientCart? _cart;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    cartUpdates.addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    cartUpdates.removeListener(_onCartUpdated);
    super.dispose();
  }

  void _onCartUpdated() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = await fetchCart();
      if (!mounted) return;
      setState(() {
        _cart = cart;
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

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier ?'),
        content:
            const Text('Tous les articles seront retirés de votre panier.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await clearCart();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de vider le panier pour le moment.')),
      );
    }
  }

  Future<void> _updateQuantity(PatientCartItem item, int quantity) async {
    try {
      await updateCartItemQuantity(item.id, quantity);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de mettre à jour la quantité.')),
      );
    }
  }

  Future<void> _removeItem(PatientCartItem item) async {
    try {
      await removeCartItem(item.id);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de retirer cet article.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            PatientTopBar(onSwitchTab: widget.onSwitchTab),
            Expanded(child: _buildBody(context)),
          ],
        ),
      );

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
    if (cart == null || cart.isEmpty) {
      return _EmptyCart(onBrowse: () => widget.onSwitchTab(1));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                cart.pharmacyName != null
                    ? 'Panier · ${cart.pharmacyName}'
                    : 'Panier',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: _clearCart,
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: GabColors.muted),
              tooltip: 'Vider le panier',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: GabColors.softGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: GabColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Votre panier ne peut contenir que les produits d'une seule pharmacie.",
                  style: TextStyle(color: GabColors.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final item in cart.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CartItemCard(
              item: item,
              formatFcfa: _formatFcfa,
              onRemove: () => _removeItem(item),
              onDecrement: item.quantity > 1
                  ? () => _updateQuantity(item, item.quantity - 1)
                  : null,
              onIncrement: item.quantity < item.availableQuantity
                  ? () => _updateQuantity(item, item.quantity + 1)
                  : null,
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GabColors.softGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Résumé',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                      child: Text('Sous-total',
                          style: TextStyle(color: GabColors.muted))),
                  Text(_formatFcfa(cart.subtotalFcfa),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Frais de livraison calculés à l'étape suivante.",
                style: TextStyle(color: GabColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: cart.isValidForCheckout
                ? () => Navigator.pushNamed(context, '/checkout')
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Certains articles de votre panier ne sont plus disponibles. Retirez-les avant de continuer.'),
                      ),
                    ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Passer à la commande'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: GabColors.muted, fontSize: 12),
            children: [
              const TextSpan(text: 'En continuant, vous acceptez nos '),
              TextSpan(
                text: 'conditions générales de vente',
                style: const TextStyle(
                    color: GabColors.primary, fontWeight: FontWeight.w700),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TermsScreen())),
              ),
              const TextSpan(text: ' et de '),
              TextSpan(
                text: 'confidentialité',
                style: const TextStyle(
                    color: GabColors.primary, fontWeight: FontWeight.w700),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen())),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.formatFcfa,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  final PatientCartItem item;
  final String Function(int) formatFcfa;
  final VoidCallback onRemove;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (item.stock.medication.dosage.isNotEmpty)
        item.stock.medication.dosage,
      if (item.stock.medication.formLabel.isNotEmpty)
        item.stock.medication.formLabel,
    ].join(' • ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: item.isValid ? GabColors.outlineVariant : GabColors.danger),
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
                  color: GabColors.softGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_outlined,
                    color: GabColors.primary, size: 30),
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
                          child: Text(item.stock.medication.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          onPressed: onRemove,
                          icon: const Icon(Icons.close, size: 18),
                          color: GabColors.muted,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (details.isNotEmpty)
                      Text(details,
                          style: const TextStyle(
                              color: GabColors.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatFcfa(item.stock.priceFcfa),
                            style: const TextStyle(
                              color: GabColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _QuantityStepper(
                          quantity: item.quantity,
                          onDecrement: onDecrement,
                          onIncrement: onIncrement,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!item.isValid) ...[
            const SizedBox(height: 8),
            const Text(
              "Cet article n'est plus disponible tel quel — retirez-le pour passer commande.",
              style: TextStyle(
                color: GabColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowse});

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
                child: Icon(Icons.shopping_bag_outlined,
                    size: 64, color: GabColors.primary.withValues(alpha: 0.3)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Votre panier est vide',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajoutez des médicaments ou produits depuis la recherche ou une fiche pharmacie.',
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
                child: const Text('Découvrir des produits'),
              ),
            ],
          ),
        ),
      );
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: GabColors.softGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove),
              iconSize: 18,
              color: GabColors.primary,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(
              width: 22,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add),
              iconSize: 18,
              color: GabColors.primary,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
}

/// Regroupement visuel des 11 statuts réels de `Order.Status` en 4 familles,
/// pour les filtres et le badge de couleur — le libellé exact affiché sur
/// chaque carte reste `PatientOrder.statusLabel` (réel, granulaire), ce
/// regroupement ne sert qu'à la couleur et au filtre.
enum _OrderBucket { pending, inProgress, delivered, cancelled }

const _inProgressStatuses = {
  'accepted',
  'preparing',
  'ready_for_pickup',
  'awaiting_courier',
  'in_delivery',
};
const _cancelledStatuses = {'cancelled', 'rejected', 'expired'};

_OrderBucket _bucketFor(String status) {
  if (status == 'pending' || status == 'changes_proposed') {
    return _OrderBucket.pending;
  }
  if (_inProgressStatuses.contains(status)) return _OrderBucket.inProgress;
  if (status == 'completed') return _OrderBucket.delivered;
  assert(_cancelledStatuses.contains(status), 'Statut de commande inconnu : $status');
  return _OrderBucket.cancelled;
}

extension on _OrderBucket {
  String get label => switch (this) {
        _OrderBucket.pending => 'En attente',
        _OrderBucket.inProgress => 'En cours',
        _OrderBucket.delivered => 'Livré',
        _OrderBucket.cancelled => 'Annulé',
      };

  IconData get icon => switch (this) {
        _OrderBucket.pending => Icons.schedule,
        _OrderBucket.inProgress => Icons.local_shipping,
        _OrderBucket.delivered => Icons.check_circle,
        _OrderBucket.cancelled => Icons.cancel,
      };

  Color get background => switch (this) {
        _OrderBucket.pending => const Color(0xFFFFDEA7),
        _OrderBucket.inProgress => const Color(0xFFA8F4B9),
        _OrderBucket.delivered => const Color(0xFF9DF6B2),
        _OrderBucket.cancelled => const Color(0xFFFFDAD6),
      };

  Color get foreground => switch (this) {
        _OrderBucket.pending => const Color(0xFF5E4200),
        _OrderBucket.inProgress => const Color(0xFF287243),
        _OrderBucket.delivered => const Color(0xFF005228),
        _OrderBucket.cancelled => GabColors.danger,
      };
}

String _formatOrderDate(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final now = DateTime.now();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return "Aujourd'hui, $time";
  if (diff == 1) return 'Hier, $time';
  const months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({required this.onSwitchTab, super.key});

  final ValueChanged<int> onSwitchTab;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  _OrderBucket? _filter;
  List<PatientOrder> _orders = [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final page = await fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = page.results;
        _hasMore = page.hasMore;
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await fetchOrders(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _orders = [..._orders, ...page.results];
        _hasMore = page.hasMore;
        _page += 1;
        _loadingMore = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de charger la suite des commandes.')),
      );
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

  List<PatientOrder> get _filteredOrders => _filter == null
      ? _orders
      : _orders.where((o) => _bucketFor(o.status) == _filter).toList();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            PatientTopBar(onSwitchTab: widget.onSwitchTab),
            Expanded(child: _buildBody(context)),
          ],
        ),
      );

  Widget _buildBody(BuildContext context) {
    final orders = _filteredOrders;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          'Mes commandes',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'Tout',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final bucket in _OrderBucket.values)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _FilterChip(
                    label: bucket.label,
                    selected: _filter == bucket,
                    onTap: () => setState(() => _filter = bucket),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Icon(Icons.cloud_off,
                    size: 44, color: GabColors.secondary),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
          )
        else if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Aucune commande',
              message: 'Aucune commande ne correspond à ce filtre.',
            ),
          )
        else ...[
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _OrderCard(
                order: order,
                formatFcfa: _formatFcfa,
                onChanged: _load,
              ),
            ),
          if (_hasMore)
            Center(
              child: _loadingMore
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    )
                  : TextButton(
                      onPressed: _loadMore,
                      child: const Text('Charger plus'),
                    ),
            ),
        ],
        const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: GabColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.help_center,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Besoin d\'aide ?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Consultez notre FAQ ou contactez le support Gab\'Pharma.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Centre d'aide indisponible en démonstration.",
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: GabColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Contact'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.formatFcfa,
    required this.onChanged,
  });

  final PatientOrder order;
  final String Function(int) formatFcfa;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final bucket = _bucketFor(order.status);
    final muted = bucket == _OrderBucket.cancelled;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: order.id),
            ),
          );
          onChanged();
        },
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RÉF : ${order.reference}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: GabColors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.pharmacyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: bucket.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(bucket.icon, size: 14, color: bucket.foreground),
                          const SizedBox(width: 4),
                          Text(
                            order.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: bucket.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: GabColors.softGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GabColors.outlineVariant),
                    ),
                    child: const Icon(Icons.medication_outlined,
                        color: GabColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.deliveryModeLabel,
                          style: const TextStyle(
                              color: GabColors.muted, fontSize: 13),
                        ),
                        Text(
                          formatFcfa(order.totalFcfa),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: muted ? GabColors.muted : GabColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatOrderDate(order.createdAt),
                    style: const TextStyle(
                      color: GabColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Détails',
                        style: TextStyle(
                          color: muted ? GabColors.muted : GabColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 18,
                          color: muted ? GabColors.muted : GabColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.onSwitchTab, super.key});

  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            PatientTopBar(onSwitchTab: onSwitchTab),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Mon profil',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: GabColors.primary,
                            child: Text('GN',
                                style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
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
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileEditScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined,
                                color: GabColors.primary),
                            tooltip: 'Modifier mes informations',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final item in const [
                    (
                      'Mon assurance',
                      Icons.health_and_safety_outlined,
                      '/insurance'
                    ),
                    (
                      'Paiements et remboursements',
                      Icons.payments_outlined,
                      '/payments'
                    ),
                    (
                      'Notifications',
                      Icons.notifications_outlined,
                      '/notifications'
                    ),
                    ('Aide et tickets', Icons.support_agent, '/support'),
                    (
                      'Sécurité et paramètres',
                      Icons.security_outlined,
                      '/security'
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          onTap: () => Navigator.pushNamed(context, item.$3),
                          leading: Icon(item.$2),
                          title: Text(item.$1),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await AuthSession.instance.clear();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _firstName = TextEditingController(text: 'Grâce');
  final _lastName = TextEditingController(text: 'Nziengui');
  final _username = TextEditingController(text: 'grace.nziengui');
  final _phone = TextEditingController(text: '07 12 34 56');
  bool _saving = false;
  String? _firstNameError;
  String? _lastNameError;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _firstNameError = _firstName.text.trim().isEmpty ? 'Prénom requis' : null;
      _lastNameError = _lastName.text.trim().isEmpty ? 'Nom requis' : null;
    });
    if (_firstNameError != null || _lastNameError != null) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations mises à jour.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: GabColors.primary),
                      ),
                    ),
                    const Text(
                      'Modifier mes informations',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GabColors.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prénom',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _firstName,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          errorText: _firstNameError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Nom',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _lastName,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          errorText: _lastNameError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Téléphone',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          prefixText: '+241 ',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Nom d'utilisateur",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _username,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('E-mail',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        enabled: false,
                        controller: TextEditingController(
                            text: 'patient.demo@gabpharma.ga'),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline),
                          helperText: 'Lecture seule',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
