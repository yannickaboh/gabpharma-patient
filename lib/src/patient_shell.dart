import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'auth_screens.dart' show TermsScreen, PrivacyPolicyScreen;
import 'core/theme.dart';
import 'widgets.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;

  void _switchTab(int index) => setState(() => _index = index);

  late final _screens = [
    PatientHomeScreen(onSwitchTab: _switchTab),
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Accueil',
              ),
              NavigationDestination(
                  icon: Icon(Icons.search), label: 'Recherche'),
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
        ),
      );
}

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({required this.onSwitchTab, super.key});

  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            PatientTopBar(onSwitchTab: onSwitchTab),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bonjour, Grâce',
                      style: TextStyle(color: GabColors.muted)),
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
                      suffixIcon: const Icon(Icons.tune,
                          color: GabColors.primary),
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
                          onTap: () =>
                              Navigator.pushNamed(context, '/support'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: GabColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          Navigator.pushNamed(context, '/order-detail'),
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commande en cours',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Livraison prévue à 14h30',
                                    style: TextStyle(
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
                        _PharmacyCard(
                          name: "Grande Pharmacie d'Olumi",
                          zone: 'Libreville',
                          distance: '1.2 km',
                          statusLabel: 'Ouvert 24h/24',
                          statusColor: GabColors.primary,
                          gradientColors: const [
                            Color(0xFF0B7A3E),
                            Color(0xFF39B27A),
                          ],
                          onTap: () =>
                              Navigator.pushNamed(context, '/pharmacy'),
                        ),
                        const SizedBox(width: 12),
                        _PharmacyCard(
                          name: 'Pharmacie du Pont-Nomba',
                          zone: 'Owendo',
                          distance: '3.5 km',
                          statusLabel: 'Ouvert',
                          statusColor: GabColors.secondary,
                          gradientColors: const [
                            Color(0xFF206B3D),
                            Color(0xFF8CD79F),
                          ],
                          onTap: () =>
                              Navigator.pushNamed(context, '/pharmacy'),
                        ),
                      ],
                    ),
                  ),
                  SectionTitle(
                    'Médicaments populaires',
                    action: TextButton(
                      onPressed: () => onSwitchTab(1),
                      child: const Text('Parcourir'),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ProductCard(
                          name: 'Paracétamol 500mg',
                          price: '2 500 FCFA',
                          onTap: () =>
                              Navigator.pushNamed(context, '/medication'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProductCard(
                          name: 'Vitamine C Booster',
                          price: '4 200 FCFA',
                          onTap: () =>
                              Navigator.pushNamed(context, '/medication'),
                        ),
                      ),
                    ],
                  ),
                  const SectionTitle('Catégories'),
                  SizedBox(
                    height: 208,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _CategoryTile(
                            label: 'Maman & Bébé',
                            icon: Icons.child_care,
                            color: const Color(0xFFFFDEA7),
                            onSurface: const Color(0xFF271900),
                            onTap: () => onSwitchTab(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: _CategoryTile(
                                  label: 'Hygiène',
                                  icon: Icons.clean_hands,
                                  color: const Color(0xFFA8F4B9),
                                  onSurface: const Color(0xFF00210D),
                                  compact: true,
                                  onTap: () => onSwitchTab(1),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _CategoryTile(
                                  label: 'Premiers soins',
                                  icon: Icons.medical_services,
                                  color: const Color(0xFF9DF6B2),
                                  onSurface: const Color(0xFF00210C),
                                  compact: true,
                                  onTap: () => onSwitchTab(1),
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
                ],
              ),
            ),
          ],
        ),
      );
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA8F4B9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF00210D), size: 22),
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
    required this.distance,
    required this.statusLabel,
    required this.statusColor,
    required this.gradientColors,
    required this.onTap,
  });

  final String name;
  final String zone;
  final String distance;
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
                      Text('$zone • $distance',
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
    required this.name,
    required this.price,
    required this.onTap,
  });

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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name ajouté au panier (démo).'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
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
                  alignment: compact
                      ? Alignment.centerLeft
                      : Alignment.topLeft,
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
    required this.name,
    required this.details,
    required this.pharmacy,
    required this.price,
    required this.inStock,
    this.zone,
  });

  final String name;
  final String details;
  final String pharmacy;
  final int price;
  final bool inStock;
  final String? zone;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.onSwitchTab, super.key});

  final ValueChanged<int> onSwitchTab;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum _SortMode { price, proximity }

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController(text: 'Paracétamol');
  String? _selectedZone = 'Akanda';
  _SortMode _sort = _SortMode.price;

  final _results = [
    _SearchResult(
      name: 'Paracétamol Mylan',
      details: '500mg • Boîte de 16 gélules',
      pharmacy: 'Pharmacie du Centre, Akanda',
      price: 1250,
      inStock: true,
      zone: 'Akanda',
    ),
    _SearchResult(
      name: 'Doliprane',
      details: '1000mg • 8 comprimés sécables',
      pharmacy: "Pharmacie de l'Estuaire",
      price: 2100,
      inStock: true,
    ),
    _SearchResult(
      name: 'Efferalgan',
      details: 'Pédiatrique • Sirop 90ml',
      pharmacy: 'Pharmacie Les Palmiers',
      price: 1850,
      inStock: false,
    ),
    _SearchResult(
      name: 'Panadol Ultra',
      details: '500mg/65mg • Boîte de 12',
      pharmacy: "Grande Pharmacie d'Owendo",
      price: 3400,
      inStock: true,
      zone: 'Owendo',
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

  List<_SearchResult> get _filteredResults {
    final list = _selectedZone == null
        ? [..._results]
        : _results.where((r) => r.zone == _selectedZone).toList();
    if (_sort == _SortMode.price) {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    return list;
  }

  void _showUnavailableFilter(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Filtre "$label" disponible une fois le catalogue connecté à l\'API.'),
        duration: const Duration(seconds: 2),
      ),
    );
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
                        onPressed: () => setState(_queryController.clear),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChipPill(
                          label: 'Akanda',
                          selected: _selectedZone == 'Akanda',
                          trailingIcon: Icons.keyboard_arrow_down,
                          onTap: () => setState(() => _selectedZone =
                              _selectedZone == 'Akanda' ? null : 'Akanda'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChipPill(
                          label: 'Owendo',
                          selected: _selectedZone == 'Owendo',
                          onTap: () => setState(() => _selectedZone =
                              _selectedZone == 'Owendo' ? null : 'Owendo'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChipPill(
                          label: 'Catégorie',
                          trailingIcon: Icons.filter_list,
                          onTap: () => _showUnavailableFilter('Catégorie'),
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
                          'Résultats (${_filteredResults.length})',
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
                  for (final result in _filteredResults)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SearchResultCard(
                        result: result,
                        formatFcfa: _formatFcfa,
                        onTap: () =>
                            Navigator.pushNamed(context, '/medication'),
                      ),
                    ),
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
              border: selected
                  ? null
                  : Border.all(color: GabColors.outlineVariant),
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
                              style:
                                  const TextStyle(color: GabColors.muted)),
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
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${result.name} ajouté au panier (démo).'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
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
                            SnackBar(
                              content: Text(
                                  'Alerte activée pour ${result.name} (démo).'),
                              duration: const Duration(seconds: 2),
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

class _CartItem {
  _CartItem(this.name, this.details, this.unitPrice, this.quantity,
      {this.maxQuantity = 9});
  final String name;
  final String details;
  final int unitPrice;
  int quantity;
  final int maxQuantity;
}

class _CartScreenState extends State<CartScreen> {
  static const _pharmacyName = 'Pharmacie Akanda';
  static const _deliveryFee = 1500;

  final _items = [
    _CartItem('Doliprane 1000mg', 'Boîte de 8 gélules', 2500, 2),
    _CartItem('Biseptine Spray', 'Flacon de 100ml', 3800, 1),
  ];

  int get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.unitPrice * item.quantity);

  int get _total => _items.isEmpty ? 0 : _subtotal + _deliveryFee;

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
        content: const Text(
            'Tous les articles seront retirés de votre panier.'),
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
    if (confirmed == true) setState(_items.clear);
  }

  void _removeItem(_CartItem item) {
    setState(() => _items.remove(item));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            PatientTopBar(onSwitchTab: widget.onSwitchTab),
            Expanded(
              child: _items.isEmpty
                  ? _EmptyCart(
                      onBrowse: () => widget.onSwitchTab(1),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Panier · $_pharmacyName',
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
                              Icon(Icons.info_outline,
                                  color: GabColors.primary, size: 20),
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
                        for (final item in _items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CartItemCard(
                              item: item,
                              formatFcfa: _formatFcfa,
                              onRemove: () => _removeItem(item),
                              onDecrement: item.quantity > 1
                                  ? () => setState(() => item.quantity -= 1)
                                  : null,
                              onIncrement: item.quantity < item.maxQuantity
                                  ? () => setState(() => item.quantity += 1)
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
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Expanded(
                                      child: Text('Sous-total',
                                          style: TextStyle(
                                              color: GabColors.muted))),
                                  Text(_formatFcfa(_subtotal),
                                      style: const TextStyle(
                                          color: GabColors.muted)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Expanded(
                                      child: Text('Livraison (Libreville)',
                                          style: TextStyle(
                                              color: GabColors.muted))),
                                  Text(_formatFcfa(_deliveryFee),
                                      style: const TextStyle(
                                          color: GabColors.muted)),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                    height: 1,
                                    color: GabColors.outlineVariant),
                              ),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Total',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  Text(
                                    _formatFcfa(_total),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: GabColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/checkout'),
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
                            style: const TextStyle(
                                color: GabColors.muted, fontSize: 12),
                            children: [
                              const TextSpan(text: 'En continuant, vous acceptez nos '),
                              TextSpan(
                                text: 'conditions générales de vente',
                                style: const TextStyle(
                                    color: GabColors.primary,
                                    fontWeight: FontWeight.w700),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const TermsScreen())),
                              ),
                              const TextSpan(text: ' et de '),
                              TextSpan(
                                text: 'confidentialité',
                                style: const TextStyle(
                                    color: GabColors.primary,
                                    fontWeight: FontWeight.w700),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const PrivacyPolicyScreen())),
                              ),
                              const TextSpan(text: '.'),
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

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.formatFcfa,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  final _CartItem item;
  final String Function(int) formatFcfa;
  final VoidCallback onRemove;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GabColors.outlineVariant),
        ),
        child: Row(
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
                        child: Text(item.name,
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
                  Text(item.details,
                      style: const TextStyle(
                          color: GabColors.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatFcfa(item.unitPrice),
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
      );
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
                    size: 64,
                    color: GabColors.primary.withValues(alpha: 0.3)),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
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
              constraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
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
              constraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({required this.onSwitchTab, super.key});

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
                          onTap: () =>
                              Navigator.pushNamed(context, '/order-detail'),
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
            ),
          ],
        ),
      );
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
