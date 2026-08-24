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

class PatientForm {
  const PatientForm({required this.code, required this.label});

  final String code;
  final String label;

  factory PatientForm.fromJson(Map<String, dynamic> json) => PatientForm(
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
    required this.latitude,
    required this.longitude,
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
  final double? latitude;
  final double? longitude;
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
        latitude: double.tryParse(json['latitude']?.toString() ?? ''),
        longitude: double.tryParse(json['longitude']?.toString() ?? ''),
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

Future<List<PatientForm>> fetchPatientForms() async {
  final json =
      await AuthSession.instance.api.getJson('mobile/patient/catalog/forms/');
  return ((json['forms'] as List?) ?? [])
      .map((e) => PatientForm.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

Future<CatalogPage> fetchCatalog({
  String query = '',
  int? categoryId,
  String? zoneCode,
  String? formCode,
  int page = 1,
}) async {
  final params = <String, String>{'page': '$page'};
  if (query.isNotEmpty) params['q'] = query;
  if (categoryId != null) params['category'] = '$categoryId';
  if (zoneCode != null && zoneCode.isNotEmpty) params['zone'] = zoneCode;
  if (formCode != null && formCode.isNotEmpty) params['form'] = formCode;
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

class PatientPaymentHistoryOrder {
  const PatientPaymentHistoryOrder({
    required this.id,
    required this.reference,
    required this.pharmacyName,
    required this.totalFcfa,
    required this.paymentStatus,
    required this.paymentStatusLabel,
    required this.refundedAmountFcfa,
  });

  final int id;
  final String reference;
  final String pharmacyName;
  final int totalFcfa;
  final String paymentStatus;
  final String paymentStatusLabel;
  final int refundedAmountFcfa;

  factory PatientPaymentHistoryOrder.fromJson(Map<String, dynamic> json) =>
      PatientPaymentHistoryOrder(
        id: (json['id'] as num).toInt(),
        reference: json['reference']?.toString() ?? '',
        pharmacyName: json['pharmacy_name']?.toString() ?? '',
        totalFcfa: (json['total_fcfa'] as num?)?.toInt() ?? 0,
        paymentStatus: json['payment_status']?.toString() ?? '',
        paymentStatusLabel: json['payment_status_label']?.toString() ?? '',
        refundedAmountFcfa:
            (json['refunded_amount_fcfa'] as num?)?.toInt() ?? 0,
      );
}

class PatientPaymentHistoryEntry {
  const PatientPaymentHistoryEntry({
    required this.reference,
    required this.provider,
    required this.providerLabel,
    required this.status,
    required this.statusLabel,
    required this.paymentMethodLabel,
    required this.canResumePayment,
    required this.createdAt,
    required this.resolvedAt,
    required this.order,
  });

  final String reference;
  final String provider;
  final String providerLabel;
  final String status;
  final String statusLabel;
  final String paymentMethodLabel;
  final bool canResumePayment;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final PatientPaymentHistoryOrder order;

  factory PatientPaymentHistoryEntry.fromJson(Map<String, dynamic> json) =>
      PatientPaymentHistoryEntry(
        reference: json['reference']?.toString() ?? '',
        provider: json['provider']?.toString() ?? '',
        providerLabel: json['provider_label']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        statusLabel: json['status_label']?.toString() ?? '',
        paymentMethodLabel: json['payment_method'] is Map
            ? (json['payment_method']['label']?.toString() ?? '')
            : '',
        // resolve_url n'est renvoyé (non nul) que pour un paiement simulé
        // encore en attente — signale qu'un "Reprendre le paiement" est
        // possible via SimulatedPaymentScreen.
        canResumePayment: json['resolve_url'] != null,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
        order: PatientPaymentHistoryOrder.fromJson(
          Map<String, dynamic>.from(json['order'] as Map),
        ),
      );
}

class PatientPaymentHistoryPage {
  const PatientPaymentHistoryPage({
    required this.count,
    required this.hasMore,
    required this.results,
  });

  final int count;
  final bool hasMore;
  final List<PatientPaymentHistoryEntry> results;
}

Future<PatientPaymentHistoryPage> fetchPaymentsHistory({int page = 1}) async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/payments/?page=$page');
  return PatientPaymentHistoryPage(
    count: (json['count'] as num?)?.toInt() ?? 0,
    hasMore: json['next'] != null,
    results: ((json['results'] as List?) ?? [])
        .map((e) => PatientPaymentHistoryEntry.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList(),
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

class PatientOrderItem {
  const PatientOrderItem({
    required this.id,
    required this.medicationName,
    required this.medicationDosage,
    required this.unitPriceFcfa,
    required this.quantity,
    required this.proposedQuantity,
    required this.lineTotalFcfa,
  });

  final int id;
  final String medicationName;
  final String medicationDosage;
  final int unitPriceFcfa;
  final int quantity;
  final int? proposedQuantity;
  final int lineTotalFcfa;

  factory PatientOrderItem.fromJson(Map<String, dynamic> json) =>
      PatientOrderItem(
        id: (json['id'] as num).toInt(),
        medicationName: json['medication_name']?.toString() ?? '',
        medicationDosage: json['medication_dosage']?.toString() ?? '',
        unitPriceFcfa: (json['unit_price_fcfa'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        proposedQuantity: (json['proposed_quantity'] as num?)?.toInt(),
        lineTotalFcfa: (json['line_total_fcfa'] as num?)?.toInt() ?? 0,
      );
}

class PatientOrderStatusEvent {
  const PatientOrderStatusEvent({
    required this.toStatusLabel,
    required this.reason,
    required this.createdAt,
  });

  final String toStatusLabel;
  final String reason;
  final DateTime? createdAt;

  factory PatientOrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      PatientOrderStatusEvent(
        toStatusLabel: json['to_status_label']?.toString() ?? '',
        reason: json['reason']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

class PatientOrderActions {
  const PatientOrderActions({
    required this.canCancel,
    required this.canAcceptChanges,
    required this.canRejectChanges,
    required this.canRetryPayment,
  });

  final bool canCancel;
  final bool canAcceptChanges;
  final bool canRejectChanges;
  final bool canRetryPayment;

  static const none = PatientOrderActions(
    canCancel: false,
    canAcceptChanges: false,
    canRejectChanges: false,
    canRetryPayment: false,
  );

  factory PatientOrderActions.fromJson(Map<String, dynamic> json) =>
      PatientOrderActions(
        canCancel: json['can_cancel'] == true,
        canAcceptChanges: json['can_accept_changes'] == true,
        canRejectChanges: json['can_reject_changes'] == true,
        canRetryPayment: json['can_retry_payment'] == true,
      );
}

/// Représente une commande, en version resumée (liste, `items`/`statusHistory`
/// vides et `actions` à `PatientOrderActions.none`) ou complète (détail,
/// `include_detail=True` côté API) selon l'endpoint appelé.
class PatientOrder {
  const PatientOrder({
    required this.id,
    required this.reference,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyPhone,
    required this.pharmacyIsOnDuty,
    required this.pharmacyIs247,
    required this.status,
    required this.statusLabel,
    required this.paymentStatusLabel,
    required this.deliveryModeLabel,
    required this.subtotalFcfa,
    required this.deliveryFeeFcfa,
    required this.insuranceDiscountFcfa,
    required this.totalFcfa,
    required this.createdAt,
    required this.items,
    required this.statusHistory,
    required this.actions,
  });

  final int id;
  final String reference;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyPhone;
  final bool pharmacyIsOnDuty;
  final bool pharmacyIs247;
  final String status;
  final String statusLabel;
  final String paymentStatusLabel;
  final String deliveryModeLabel;
  final int subtotalFcfa;
  final int deliveryFeeFcfa;
  final int insuranceDiscountFcfa;
  final int totalFcfa;
  final DateTime? createdAt;
  final List<PatientOrderItem> items;
  final List<PatientOrderStatusEvent> statusHistory;
  final PatientOrderActions actions;

  factory PatientOrder.fromJson(Map<String, dynamic> json) {
    final pharmacy = (json['pharmacy'] as Map?) ?? const {};
    return PatientOrder(
      id: (json['id'] as num).toInt(),
      reference: json['reference']?.toString() ?? '',
      pharmacyName: pharmacy['name']?.toString() ?? '',
      pharmacyAddress: pharmacy['address']?.toString() ?? '',
      pharmacyPhone: pharmacy['phone']?.toString() ?? '',
      pharmacyIsOnDuty: pharmacy['is_on_duty'] == true,
      pharmacyIs247: pharmacy['is_24_7'] == true,
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      paymentStatusLabel: json['payment_status_label']?.toString() ?? '',
      deliveryModeLabel: json['delivery_mode_label']?.toString() ?? '',
      subtotalFcfa: (json['subtotal_fcfa'] as num?)?.toInt() ?? 0,
      deliveryFeeFcfa: (json['delivery_fee_fcfa'] as num?)?.toInt() ?? 0,
      insuranceDiscountFcfa:
          (json['insurance_discount_fcfa'] as num?)?.toInt() ?? 0,
      totalFcfa: (json['total_fcfa'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      items: ((json['items'] as List?) ?? [])
          .map((e) =>
              PatientOrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      statusHistory: ((json['status_history'] as List?) ?? [])
          .map((e) => PatientOrderStatusEvent.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      actions: json['actions'] is Map
          ? PatientOrderActions.fromJson(
              Map<String, dynamic>.from(json['actions'] as Map))
          : PatientOrderActions.none,
    );
  }
}

class PatientOrderPage {
  const PatientOrderPage({
    required this.count,
    required this.hasMore,
    required this.results,
  });

  final int count;
  final bool hasMore;
  final List<PatientOrder> results;
}

Future<PatientOrderPage> fetchOrders({int page = 1}) async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/orders/?page=$page');
  return PatientOrderPage(
    count: (json['count'] as num?)?.toInt() ?? 0,
    hasMore: json['next'] != null,
    results: ((json['results'] as List?) ?? [])
        .map((e) => PatientOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

Future<PatientOrder> fetchOrderDetail(int orderId) async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/orders/$orderId/');
  return PatientOrder.fromJson(json);
}

Future<PatientOrder> cancelOrder(int orderId, String reason) async {
  final json = await AuthSession.instance.api.postJson(
    'mobile/patient/orders/$orderId/cancel/',
    {'reason': reason},
  );
  return PatientOrder.fromJson(json);
}

Future<PatientOrder> acceptOrderChanges(int orderId) async {
  final json = await AuthSession.instance.api
      .postJson('mobile/patient/orders/$orderId/accept-changes/', {});
  return PatientOrder.fromJson(json);
}

Future<PatientOrder> rejectOrderChanges(int orderId, String reason) async {
  final json = await AuthSession.instance.api.postJson(
    'mobile/patient/orders/$orderId/reject-changes/',
    {'reason': reason},
  );
  return PatientOrder.fromJson(json);
}

class PatientRetryPaymentResult {
  const PatientRetryPaymentResult({
    required this.order,
    required this.transactionReference,
  });

  final PatientOrder order;
  final String? transactionReference;

  factory PatientRetryPaymentResult.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map?;
    return PatientRetryPaymentResult(
      order: PatientOrder.fromJson(Map<String, dynamic>.from(json['order'] as Map)),
      transactionReference:
          (payment?['transaction'] as Map?)?['reference']?.toString(),
    );
  }
}

Future<PatientRetryPaymentResult> retryOrderPayment(int orderId) async {
  final json = await AuthSession.instance.api
      .postJson('mobile/patient/orders/$orderId/retry-payment/', {});
  return PatientRetryPaymentResult.fromJson(json);
}

class InsurancePlanCategoryRate {
  const InsurancePlanCategoryRate({
    required this.categoryName,
    required this.coverageRate,
  });

  final String categoryName;
  final int coverageRate;

  factory InsurancePlanCategoryRate.fromJson(Map<String, dynamic> json) =>
      InsurancePlanCategoryRate(
        categoryName: json['category_name']?.toString() ?? '',
        coverageRate: (json['coverage_rate'] as num).toInt(),
      );
}

class InsurancePlan {
  const InsurancePlan({
    required this.id,
    required this.name,
    required this.defaultCoverageRate,
    required this.categoryRates,
  });

  final int id;
  final String name;
  final int defaultCoverageRate;
  final List<InsurancePlanCategoryRate> categoryRates;

  factory InsurancePlan.fromJson(Map<String, dynamic> json) => InsurancePlan(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        defaultCoverageRate: (json['default_coverage_rate'] as num).toInt(),
        categoryRates: ((json['category_rates'] as List?) ?? [])
            .map((e) => InsurancePlanCategoryRate.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class PatientInsurer {
  const PatientInsurer({
    required this.id,
    required this.name,
    required this.plans,
  });

  final int id;
  final String name;
  final List<InsurancePlan> plans;

  factory PatientInsurer.fromJson(Map<String, dynamic> json) =>
      PatientInsurer(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        plans: ((json['plans'] as List?) ?? [])
            .map((e) =>
                InsurancePlan.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

Future<List<PatientInsurer>> fetchInsurers() async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/insurance/insurers/');
  return ((json['insurers'] as List?) ?? [])
      .map((e) =>
          PatientInsurer.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

class PatientInsuranceAffiliation {
  const PatientInsuranceAffiliation({
    required this.id,
    required this.planId,
    required this.planName,
    required this.defaultCoverageRate,
    required this.insurerName,
    required this.memberNumber,
  });

  final int id;
  final int planId;
  final String planName;
  final int defaultCoverageRate;
  final String insurerName;
  final String memberNumber;

  factory PatientInsuranceAffiliation.fromJson(Map<String, dynamic> json) {
    final plan = Map<String, dynamic>.from(json['plan'] as Map);
    final insurer = Map<String, dynamic>.from(plan['insurer'] as Map);
    return PatientInsuranceAffiliation(
      id: (json['id'] as num).toInt(),
      planId: (plan['id'] as num).toInt(),
      planName: plan['name']?.toString() ?? '',
      defaultCoverageRate: (plan['default_coverage_rate'] as num).toInt(),
      insurerName: insurer['name']?.toString() ?? '',
      memberNumber: json['member_number']?.toString() ?? '',
    );
  }
}

Future<PatientInsuranceAffiliation?> fetchInsuranceAffiliation() async {
  final json = await AuthSession.instance.api
      .getJson('mobile/patient/insurance/affiliation/');
  final affiliation = json['affiliation'];
  if (affiliation == null) return null;
  return PatientInsuranceAffiliation.fromJson(
      Map<String, dynamic>.from(affiliation as Map));
}

Future<PatientInsuranceAffiliation> saveInsuranceAffiliation({
  required int planId,
  required String memberNumber,
}) async {
  final json = await AuthSession.instance.api.postJson(
    'mobile/patient/insurance/affiliation/',
    {'plan_id': planId, 'member_number': memberNumber},
  );
  return PatientInsuranceAffiliation.fromJson(
      Map<String, dynamic>.from(json['affiliation'] as Map));
}

Future<void> deleteInsuranceAffiliation() async {
  await AuthSession.instance.api
      .deleteJson('mobile/patient/insurance/affiliation/');
}

class PatientNotification {
  const PatientNotification({
    required this.icon,
    required this.tone,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.targetType,
    required this.targetId,
  });

  final String icon;
  final String tone;
  final String title;
  final String description;
  final DateTime timestamp;
  final String targetType;
  final int? targetId;

  factory PatientNotification.fromJson(Map<String, dynamic> json) =>
      PatientNotification(
        icon: json['icon']?.toString() ?? 'notifications',
        tone: json['tone']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        timestamp: DateTime.parse(json['timestamp'].toString()),
        targetType: json['target_type']?.toString() ?? '',
        targetId: (json['target_id'] as num?)?.toInt(),
      );
}

Future<List<PatientNotification>> fetchNotifications() async {
  final json =
      await AuthSession.instance.api.getJson('mobile/notifications/');
  return ((json['notifications'] as List?) ?? [])
      .map((e) => PatientNotification.fromJson(
          Map<String, dynamic>.from(e as Map)))
      .toList();
}

class PatientSupportCategory {
  const PatientSupportCategory({required this.code, required this.label});

  final String code;
  final String label;

  factory PatientSupportCategory.fromJson(Map<String, dynamic> json) =>
      PatientSupportCategory(
        code: json['code']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}

Future<List<PatientSupportCategory>> fetchSupportCategories() async {
  final json =
      await AuthSession.instance.api.getJson('mobile/support/categories/');
  return ((json['categories'] as List?) ?? [])
      .map((e) => PatientSupportCategory.fromJson(
          Map<String, dynamic>.from(e as Map)))
      .toList();
}

class PatientTicketAttachment {
  const PatientTicketAttachment({
    required this.id,
    required this.originalName,
  });

  final int id;
  final String originalName;

  factory PatientTicketAttachment.fromJson(Map<String, dynamic> json) =>
      PatientTicketAttachment(
        id: (json['id'] as num).toInt(),
        originalName: json['original_name']?.toString() ?? '',
      );
}

class PatientTicketMessage {
  const PatientTicketMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    required this.attachments,
  });

  final int id;
  final int? authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final List<PatientTicketAttachment> attachments;

  factory PatientTicketMessage.fromJson(Map<String, dynamic> json) =>
      PatientTicketMessage(
        id: (json['id'] as num).toInt(),
        authorId: (json['author_id'] as num?)?.toInt(),
        authorName: json['author_name']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.parse(json['created_at'].toString()),
        attachments: ((json['attachments'] as List?) ?? [])
            .map((e) => PatientTicketAttachment.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class PatientSupportTicket {
  const PatientSupportTicket({
    required this.id,
    required this.reference,
    required this.subject,
    required this.category,
    required this.categoryLabel,
    required this.priority,
    required this.priorityLabel,
    required this.status,
    required this.statusLabel,
    required this.isSlaOverdue,
    required this.orderReference,
    required this.lastActivityAt,
    required this.createdAt,
    required this.messages,
  });

  final int id;
  final String reference;
  final String subject;
  final String category;
  final String categoryLabel;
  final String priority;
  final String priorityLabel;
  final String status;
  final String statusLabel;
  final bool isSlaOverdue;
  final String? orderReference;
  final DateTime lastActivityAt;
  final DateTime createdAt;
  final List<PatientTicketMessage>? messages;

  factory PatientSupportTicket.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map?;
    return PatientSupportTicket(
      id: (json['id'] as num).toInt(),
      reference: json['reference']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      priorityLabel: json['priority_label']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      isSlaOverdue: json['is_sla_overdue'] == true,
      orderReference: order?['reference']?.toString(),
      lastActivityAt: DateTime.parse(json['last_activity_at'].toString()),
      createdAt: DateTime.parse(json['created_at'].toString()),
      messages: json['messages'] == null
          ? null
          : (json['messages'] as List)
              .map((e) => PatientTicketMessage.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList(),
    );
  }
}

class PatientSupportTicketPage {
  const PatientSupportTicketPage({
    required this.hasMore,
    required this.results,
  });

  final bool hasMore;
  final List<PatientSupportTicket> results;
}

Future<PatientSupportTicketPage> fetchSupportTickets({int page = 1}) async {
  final json = await AuthSession.instance.api
      .getJson('mobile/support/tickets/?page=$page');
  return PatientSupportTicketPage(
    hasMore: json['next'] != null,
    results: ((json['results'] as List?) ?? [])
        .map((e) => PatientSupportTicket.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

Future<PatientSupportTicket> createSupportTicket({
  required String subject,
  required String category,
  required String message,
  int? orderId,
}) async {
  final json = await AuthSession.instance.api.postJson(
    'mobile/support/tickets/',
    {
      'subject': subject,
      'category': category,
      'message': message,
      if (orderId != null) 'order': orderId,
    },
  );
  return PatientSupportTicket.fromJson(json);
}

Future<PatientSupportTicket> fetchSupportTicketDetail(int ticketId) async {
  final json = await AuthSession.instance.api
      .getJson('mobile/support/tickets/$ticketId/');
  return PatientSupportTicket.fromJson(json);
}

Future<PatientSupportTicket> replySupportTicket(
  int ticketId,
  String body,
) async {
  final json = await AuthSession.instance.api.postJson(
    'mobile/support/tickets/$ticketId/reply/',
    {'body': body},
  );
  return PatientSupportTicket.fromJson(json);
}

class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.email,
    required this.phone,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.roleLabel,
    required this.statusLabel,
  });

  final int id;
  final String email;
  final String phone;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String roleLabel;
  final String statusLabel;

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    final combined =
        '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
            .toUpperCase();
    if (combined.isNotEmpty) return combined;
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) =>
      PatientProfile(
        id: (json['id'] as num).toInt(),
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        roleLabel: json['role_label']?.toString() ?? '',
        statusLabel: json['status_label']?.toString() ?? '',
      );
}

Future<PatientProfile> fetchProfile() async {
  final json = await AuthSession.instance.api.getJson('mobile/profile/');
  return PatientProfile.fromJson(
      Map<String, dynamic>.from(json['profile'] as Map));
}

Future<PatientProfile> updateProfile({
  required String firstName,
  required String lastName,
  String phone = '',
  String username = '',
}) async {
  final json = await AuthSession.instance.api.patchJson('mobile/profile/', {
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'username': username,
  });
  return PatientProfile.fromJson(
      Map<String, dynamic>.from(json['profile'] as Map));
}

Future<void> changePassword({
  required String currentPassword,
  required String newPassword1,
  required String newPassword2,
}) async {
  await AuthSession.instance.api.postJson('mobile/profile/password/', {
    'current_password': currentPassword,
    'new_password1': newPassword1,
    'new_password2': newPassword2,
  });
}

/// Envoie un code à 6 chiffres à [newEmail] ; rappeler cette même fonction
/// sert aussi de renvoi (pas d'endpoint de renvoi dédié côté backend).
/// Peut lever une [ApiException] avec statusCode 429 si le cooldown serveur
/// n'est pas encore écoulé.
Future<AuthChallenge> requestEmailChange({
  required String currentPassword,
  required String newEmail,
}) async {
  final json =
      await AuthSession.instance.api.postJson('mobile/profile/email-change/', {
    'current_password': currentPassword,
    'new_email': newEmail,
  });
  return AuthChallenge.fromJson(
    Map<String, dynamic>.from(json['challenge'] as Map),
  );
}

Future<PatientProfile> verifyEmailChange({
  required String challengeId,
  required String code,
}) async {
  final json =
      await AuthSession.instance.api.postJson('mobile/profile/email-change/verify/', {
    'challenge_id': challengeId,
    'code': code,
  });
  return PatientProfile.fromJson(
      Map<String, dynamic>.from(json['profile'] as Map));
}

/// Désactivation réversible (conformité App Store/Play Store) : la
/// réactivation se fait par simple reconnexion + 2FA, aucun endpoint
/// séparé côté backend.
Future<void> deactivateAccount({required String currentPassword}) async {
  await AuthSession.instance.api.postJson('mobile/profile/deactivate/', {
    'current_password': currentPassword,
  });
}

/// Upsert par `push_token` côté backend : réutilisable aussi bien pour un
/// premier enregistrement que pour signaler qu'un token a été rafraîchi.
Future<void> registerDevice({
  required String pushToken,
  required String platform,
  String deviceLabel = '',
}) async {
  await AuthSession.instance.api.postJson('mobile/devices/', {
    'push_token': pushToken,
    'platform': platform,
    'device_label': deviceLabel,
  });
}

Future<void> unregisterDevice({required String pushToken}) async {
  await AuthSession.instance.api.postJson('mobile/devices/unregister/', {
    'push_token': pushToken,
  });
}
