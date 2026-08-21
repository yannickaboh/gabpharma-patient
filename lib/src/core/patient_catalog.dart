import 'package:flutter/foundation.dart';

import 'auth_session.dart';

/// Incrémenté à chaque mutation réussie du panier (ajout/maj/suppression/
/// vidage), quel que soit l'écran d'origine. CartScreen et le badge de la
/// barre de navigation l'écoutent pour rester synchronisés sans dépendre
/// d'un unique écran source de vérité.
final ValueNotifier<int> cartUpdates = ValueNotifier<int>(0);

class PatientCategory {
  const PatientCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory PatientCategory.fromJson(Map<String, dynamic> json) =>
      PatientCategory(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
      );
}

class PatientZone {
  const PatientZone({required this.code, required this.label});

  final String code;
  final String label;

  factory PatientZone.fromJson(Map<String, dynamic> json) => PatientZone(
        code: json['code']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}

class CatalogMedication {
  const CatalogMedication({
    required this.medicationId,
    required this.name,
    required this.dci,
    required this.dosage,
    required this.formLabel,
    required this.requiresPrescription,
    required this.isFavorite,
  });

  final int medicationId;
  final String name;
  final String dci;
  final String dosage;
  final String formLabel;
  final bool requiresPrescription;
  final bool isFavorite;

  factory CatalogMedication.fromJson(Map<String, dynamic> json) =>
      CatalogMedication(
        medicationId: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        dci: json['dci']?.toString() ?? '',
        dosage: json['dosage']?.toString() ?? '',
        formLabel: json['form_label']?.toString() ?? '',
        requiresPrescription: json['requires_prescription'] == true,
        isFavorite: json['is_favorite'] == true,
      );
}

class CatalogPharmacy {
  const CatalogPharmacy({
    required this.id,
    required this.name,
    required this.zoneLabel,
  });

  final int id;
  final String name;
  final String zoneLabel;

  factory CatalogPharmacy.fromJson(Map<String, dynamic> json) =>
      CatalogPharmacy(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        zoneLabel: json['zone_label']?.toString() ?? '',
      );
}

class CatalogStock {
  const CatalogStock({
    required this.id,
    required this.medication,
    required this.pharmacy,
    required this.priceFcfa,
    required this.quantity,
    required this.isAvailable,
    required this.lowStockThreshold,
  });

  final int id;
  final CatalogMedication medication;
  final CatalogPharmacy pharmacy;
  final int priceFcfa;
  final int quantity;
  final bool isAvailable;
  final int? lowStockThreshold;

  bool get inStock => isAvailable && quantity > 0;
  bool get isLowStock =>
      lowStockThreshold != null && quantity <= lowStockThreshold!;

  factory CatalogStock.fromJson(Map<String, dynamic> json) => CatalogStock(
        id: (json['id'] as num).toInt(),
        medication: CatalogMedication.fromJson(
          Map<String, dynamic>.from(json['medication'] as Map),
        ),
        pharmacy: CatalogPharmacy.fromJson(
          Map<String, dynamic>.from(json['pharmacy'] as Map),
        ),
        priceFcfa: (json['price_fcfa'] as num).toInt(),
        quantity: (json['quantity'] as num).toInt(),
        isAvailable: json['is_available'] == true,
        lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt(),
      );
}

class PharmacyService {
  const PharmacyService({required this.code, required this.label});

  final String code;
  final String label;

  factory PharmacyService.fromJson(Map<String, dynamic> json) =>
      PharmacyService(
        code: json['code']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}

class PharmacyDetail {
  const PharmacyDetail({
    required this.id,
    required this.name,
    required this.zoneLabel,
    required this.address,
    required this.phone,
    required this.isOnDuty,
    required this.is24h,
    required this.isOpenNow,
    required this.acceptsCashOnDelivery,
    required this.services,
    required this.acceptedPlanCount,
  });

  final int id;
  final String name;
  final String zoneLabel;
  final String address;
  final String phone;
  final bool isOnDuty;
  final bool is24h;
  final bool isOpenNow;
  final bool acceptsCashOnDelivery;
  final List<PharmacyService> services;
  final int acceptedPlanCount;

  factory PharmacyDetail.fromJson(Map<String, dynamic> json) =>
      PharmacyDetail(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        zoneLabel: json['zone_label']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        isOnDuty: json['is_on_duty'] == true,
        is24h: json['is_24_7'] == true,
        isOpenNow: json['is_open_now'] == true,
        acceptsCashOnDelivery: json['accepts_cash_on_delivery'] == true,
        services: ((json['services'] as List?) ?? [])
            .map((e) =>
                PharmacyService.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        acceptedPlanCount:
            ((json['accepted_plan_ids'] as List?) ?? []).length,
      );
}

class CatalogPage {
  const CatalogPage({
    required this.count,
    required this.hasMore,
    required this.results,
  });

  final int count;
  final bool hasMore;
  final List<CatalogStock> results;
}

Future<List<PatientCategory>> fetchPatientCategories() async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/catalog/categories/');
  return ((json['categories'] as List?) ?? [])
      .map((e) => PatientCategory.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

Future<List<PatientZone>> fetchPatientZones() async {
  final json = await AuthSession.instance.api.getJson('mobile/patient/zones/');
  return ((json['zones'] as List?) ?? [])
      .map((e) => PatientZone.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

Future<CatalogPage> fetchCatalog({
  String query = '',
  int? categoryId,
  String? zoneCode,
  int page = 1,
}) async {
  final params = <String, String>{'page': '$page'};
  if (query.isNotEmpty) params['q'] = query;
  if (categoryId != null) params['category'] = '$categoryId';
  if (zoneCode != null && zoneCode.isNotEmpty) params['zone'] = zoneCode;
  final qs = params.entries
      .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
  final json =
      await AuthSession.instance.api.getJson('mobile/patient/catalog/?$qs');
  return CatalogPage(
    count: (json['count'] as num?)?.toInt() ?? 0,
    hasMore: json['next'] != null,
    results: ((json['results'] as List?) ?? [])
        .map((e) => CatalogStock.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

Future<CatalogStock> fetchStockDetail(int stockId) async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/catalog/stocks/$stockId/');
  return CatalogStock.fromJson(json);
}

Future<PharmacyDetail> fetchPharmacyDetail(int pharmacyId) async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/pharmacies/$pharmacyId/');
  return PharmacyDetail.fromJson(json);
}

Future<CatalogPage> fetchPharmacyCatalog(int pharmacyId, {int page = 1}) async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/pharmacies/$pharmacyId/catalog/?page=$page');
  return CatalogPage(
    count: (json['count'] as num?)?.toInt() ?? 0,
    hasMore: json['next'] != null,
    results: ((json['results'] as List?) ?? [])
        .map((e) => CatalogStock.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class PatientFavorite {
  const PatientFavorite({
    required this.id,
    required this.medication,
    required this.offerCount,
    required this.bestPriceFcfa,
    required this.isLowStock,
  });

  final int id;
  final CatalogMedication medication;
  final int offerCount;
  final int? bestPriceFcfa;
  final bool isLowStock;

  factory PatientFavorite.fromJson(Map<String, dynamic> json) =>
      PatientFavorite(
        id: (json['id'] as num).toInt(),
        medication: CatalogMedication.fromJson(
          Map<String, dynamic>.from(json['medication'] as Map),
        ),
        offerCount: (json['offer_count'] as num?)?.toInt() ?? 0,
        bestPriceFcfa: (json['best_price_fcfa'] as num?)?.toInt(),
        isLowStock: json['is_low_stock'] == true,
      );
}

Future<List<PatientFavorite>> fetchFavorites() async {
  final json =
      await AuthSession.instance.api.getJson('mobile/patient/favorites/');
  return ((json['favorites'] as List?) ?? [])
      .map((e) => PatientFavorite.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

Future<PatientFavorite> addFavorite(int medicationId) async {
  final json = await AuthSession.instance.api.postJson(
    'mobile/patient/favorites/',
    {'medication_id': medicationId},
  );
  return PatientFavorite.fromJson(json);
}

Future<void> removeFavorite(int favoriteId) async {
  await AuthSession.instance.api.deleteJson('mobile/patient/favorites/$favoriteId/');
}

/// Trouve un stock réel pour une fiche médicament (l'API n'expose pas de
/// détail "médicament tous pharmacies" — même approximation que le détail
/// médicament) : renvoie l'id du stock le moins cher, ou null si plus
/// aucune pharmacie n'a ce médicament en stock.
Future<int?> findCheapestStockId(String medicationName) async {
  final page = await fetchCatalog(query: medicationName);
  if (page.results.isEmpty) return null;
  final sorted = [...page.results]
    ..sort((a, b) => a.priceFcfa.compareTo(b.priceFcfa));
  return sorted.first.id;
}

class PatientCartItem {
  const PatientCartItem({
    required this.id,
    required this.stock,
    required this.quantity,
    required this.lineTotalFcfa,
    required this.availableQuantity,
    required this.isValid,
  });

  final int id;
  final CatalogStock stock;
  final int quantity;
  final int lineTotalFcfa;
  final int availableQuantity;
  final bool isValid;

  factory PatientCartItem.fromJson(Map<String, dynamic> json) =>
      PatientCartItem(
        id: (json['id'] as num).toInt(),
        stock: CatalogStock.fromJson(
          Map<String, dynamic>.from(json['stock'] as Map),
        ),
        quantity: (json['quantity'] as num).toInt(),
        lineTotalFcfa: (json['line_total_fcfa'] as num).toInt(),
        availableQuantity: (json['available_quantity'] as num).toInt(),
        isValid: json['is_valid'] == true,
      );
}

class PatientCart {
  const PatientCart({
    required this.id,
    required this.pharmacyName,
    required this.items,
    required this.itemsCount,
    required this.subtotalFcfa,
    required this.isEmpty,
    required this.isValidForCheckout,
  });

  final int id;
  final String? pharmacyName;
  final List<PatientCartItem> items;
  final int itemsCount;
  final int subtotalFcfa;
  final bool isEmpty;
  final bool isValidForCheckout;

  factory PatientCart.fromJson(Map<String, dynamic> json) => PatientCart(
        id: (json['id'] as num).toInt(),
        pharmacyName: (json['pharmacy'] as Map?)?['name']?.toString(),
        items: ((json['items'] as List?) ?? [])
            .map((e) =>
                PatientCartItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
        subtotalFcfa: (json['subtotal_fcfa'] as num?)?.toInt() ?? 0,
        isEmpty: json['is_empty'] == true,
        isValidForCheckout: json['is_valid_for_checkout'] == true,
      );
}

Future<PatientCart> fetchCart() async {
  final json = await AuthSession.instance.api.getJson('mobile/patient/cart/');
  return PatientCart.fromJson(json);
}

Future<PatientCart> addCartItem(int stockId, int quantity) async {
  final json = await AuthSession.instance.api.postJson(
    'mobile/patient/cart/items/',
    {'stock_id': stockId, 'quantity': quantity},
  );
  cartUpdates.value++;
  return PatientCart.fromJson(Map<String, dynamic>.from(json['cart'] as Map));
}

Future<PatientCart> updateCartItemQuantity(int itemId, int quantity) async {
  final json = await AuthSession.instance.api.patchJson(
    'mobile/patient/cart/items/$itemId/',
    {'quantity': quantity},
  );
  cartUpdates.value++;
  return PatientCart.fromJson(Map<String, dynamic>.from(json['cart'] as Map));
}

Future<PatientCart> removeCartItem(int itemId) async {
  final json = await AuthSession.instance.api
      .deleteJson('mobile/patient/cart/items/$itemId/');
  cartUpdates.value++;
  return PatientCart.fromJson(json);
}

Future<PatientCart> clearCart() async {
  final json =
      await AuthSession.instance.api.postJson('mobile/patient/cart/clear/', {});
  cartUpdates.value++;
  return PatientCart.fromJson(json);
}

class PatientPaymentMethod {
  const PatientPaymentMethod({
    required this.id,
    required this.kind,
    required this.label,
  });

  final int id;
  final String kind;
  final String label;

  bool get isCod => kind == 'cod';

  factory PatientPaymentMethod.fromJson(Map<String, dynamic> json) =>
      PatientPaymentMethod(
        id: (json['id'] as num).toInt(),
        kind: json['kind']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}

Future<List<PatientPaymentMethod>> fetchPaymentMethods() async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/payment-methods/');
  return ((json['payment_methods'] as List?) ?? [])
      .map((e) =>
          PatientPaymentMethod.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Sous-ensemble de la commande renvoyée par `POST /checkout/`, limité aux
/// champs affichés par l'app pour ce module (pas de détail des articles :
/// c'est le rôle de l'écran Détail commande, module suivant).
class PatientCheckoutOrder {
  const PatientCheckoutOrder({
    required this.reference,
    required this.pharmacyName,
    required this.deliveryModeLabel,
    required this.subtotalFcfa,
    required this.deliveryFeeFcfa,
    required this.insuranceDiscountFcfa,
    required this.totalFcfa,
    required this.paymentStatusLabel,
  });

  final String reference;
  final String pharmacyName;
  final String deliveryModeLabel;
  final int subtotalFcfa;
  final int deliveryFeeFcfa;
  final int insuranceDiscountFcfa;
  final int totalFcfa;
  final String paymentStatusLabel;

  factory PatientCheckoutOrder.fromJson(Map<String, dynamic> json) =>
      PatientCheckoutOrder(
        reference: json['reference']?.toString() ?? '',
        pharmacyName: (json['pharmacy'] as Map?)?['name']?.toString() ?? '',
        deliveryModeLabel: json['delivery_mode_label']?.toString() ?? '',
        subtotalFcfa: (json['subtotal_fcfa'] as num?)?.toInt() ?? 0,
        deliveryFeeFcfa: (json['delivery_fee_fcfa'] as num?)?.toInt() ?? 0,
        insuranceDiscountFcfa:
            (json['insurance_discount_fcfa'] as num?)?.toInt() ?? 0,
        totalFcfa: (json['total_fcfa'] as num?)?.toInt() ?? 0,
        paymentStatusLabel: json['payment_status_label']?.toString() ?? '',
      );
}

class PatientCheckoutResult {
  const PatientCheckoutResult({
    required this.order,
    required this.paymentRequired,
    required this.paymentTransactionReference,
    required this.cart,
  });

  final PatientCheckoutOrder order;
  final bool paymentRequired;
  final String? paymentTransactionReference;
  final PatientCart cart;

  factory PatientCheckoutResult.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map?;
    return PatientCheckoutResult(
      order: PatientCheckoutOrder.fromJson(
          Map<String, dynamic>.from(json['order'] as Map)),
      paymentRequired: payment?['required'] == true,
      paymentTransactionReference:
          (payment?['transaction'] as Map?)?['reference']?.toString(),
      cart: PatientCart.fromJson(
          Map<String, dynamic>.from(json['cart'] as Map)),
    );
  }
}

Future<PatientCheckoutResult> checkoutPatientCart({
  required String deliveryMode,
  required String deliveryAddress,
  required String deliveryZone,
  required int paymentMethodId,
}) async {
  final json = await AuthSession.instance.api.postJson(
    'mobile/patient/checkout/',
    {
      'delivery_mode': deliveryMode,
      'delivery_address': deliveryAddress,
      'delivery_zone': deliveryZone,
      'payment_method_id': paymentMethodId,
    },
  );
  cartUpdates.value++;
  return PatientCheckoutResult.fromJson(json);
}

class PatientPaymentTransaction {
  const PatientPaymentTransaction({
    required this.reference,
    required this.status,
    required this.statusLabel,
  });

  final String reference;
  final String status;
  final String statusLabel;

  bool get succeeded => status == 'succeeded';

  factory PatientPaymentTransaction.fromJson(Map<String, dynamic> json) =>
      PatientPaymentTransaction(
        reference: json['reference']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        statusLabel: json['status_label']?.toString() ?? '',
      );
}

class PatientPaymentResolution {
  const PatientPaymentResolution({
    required this.transaction,
    required this.order,
  });

  final PatientPaymentTransaction transaction;
  final PatientCheckoutOrder order;

  factory PatientPaymentResolution.fromJson(Map<String, dynamic> json) =>
      PatientPaymentResolution(
        transaction: PatientPaymentTransaction.fromJson(
          Map<String, dynamic>.from(json['transaction'] as Map),
        ),
        order: PatientCheckoutOrder.fromJson(
          Map<String, dynamic>.from(json['order'] as Map),
        ),
      );
}

Future<PatientPaymentResolution> resolveSimulatedPayment({
  required String reference,
  required bool succeeded,
}) async {
  final json = await AuthSession.instance.api.postJson(
    'mobile/patient/payments/$reference/simulate/resolve/',
    {'outcome': succeeded ? 'success' : 'failed'},
  );
  return PatientPaymentResolution.fromJson(json);
}
