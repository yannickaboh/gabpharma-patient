import 'auth_session.dart';

class PatientMedicationSummary {
  const PatientMedicationSummary({
    required this.name,
    required this.categoryName,
  });

  final String name;
  final String categoryName;

  factory PatientMedicationSummary.fromJson(Map<String, dynamic> json) =>
      PatientMedicationSummary(
        name: json['name']?.toString() ?? '',
        categoryName:
            (json['category'] as Map?)?['name']?.toString() ?? '',
      );
}

class PatientPharmacySummary {
  const PatientPharmacySummary({
    required this.id,
    required this.name,
    required this.zoneLabel,
    required this.isOnDuty,
    required this.is24h,
  });

  final int id;
  final String name;
  final String zoneLabel;
  final bool isOnDuty;
  final bool is24h;

  factory PatientPharmacySummary.fromJson(Map<String, dynamic> json) =>
      PatientPharmacySummary(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        zoneLabel: json['zone_label']?.toString() ?? '',
        isOnDuty: json['is_on_duty'] == true,
        is24h: json['is_24_7'] == true,
      );
}

class FeaturedStock {
  const FeaturedStock({
    required this.id,
    required this.medication,
    required this.pharmacy,
    required this.priceFcfa,
  });

  final int id;
  final PatientMedicationSummary medication;
  final PatientPharmacySummary pharmacy;
  final int priceFcfa;

  factory FeaturedStock.fromJson(Map<String, dynamic> json) => FeaturedStock(
        id: (json['id'] as num).toInt(),
        medication: PatientMedicationSummary.fromJson(
          Map<String, dynamic>.from(json['medication'] as Map),
        ),
        pharmacy: PatientPharmacySummary.fromJson(
          Map<String, dynamic>.from(json['pharmacy'] as Map),
        ),
        priceFcfa: (json['price_fcfa'] as num).toInt(),
      );
}

class PatientCartSummary {
  const PatientCartSummary({required this.itemsCount});

  final int itemsCount;

  factory PatientCartSummary.fromJson(Map<String, dynamic> json) =>
      PatientCartSummary(
        itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      );
}

class PatientActiveOrder {
  const PatientActiveOrder({
    required this.id,
    required this.reference,
    required this.statusLabel,
    required this.deliveryModeLabel,
  });

  final int id;
  final String reference;
  final String statusLabel;
  final String deliveryModeLabel;

  factory PatientActiveOrder.fromJson(Map<String, dynamic> json) =>
      PatientActiveOrder(
        id: (json['id'] as num).toInt(),
        reference: json['reference']?.toString() ?? '',
        statusLabel: json['status_label']?.toString() ?? '',
        deliveryModeLabel: json['delivery_mode_label']?.toString() ?? '',
      );
}

class PatientSummary {
  const PatientSummary({
    required this.profile,
    required this.cart,
    required this.activeOrder,
    required this.favoriteCount,
    required this.supportOpenCount,
    required this.featuredStocks,
  });

  final AuthUser profile;
  final PatientCartSummary cart;
  final PatientActiveOrder? activeOrder;
  final int favoriteCount;
  final int supportOpenCount;
  final List<FeaturedStock> featuredStocks;

  factory PatientSummary.fromJson(Map<String, dynamic> json) =>
      PatientSummary(
        profile: AuthUser.fromJson(
          Map<String, dynamic>.from(json['profile'] as Map),
        ),
        cart: PatientCartSummary.fromJson(
          Map<String, dynamic>.from(json['cart'] as Map),
        ),
        activeOrder: json['active_order'] == null
            ? null
            : PatientActiveOrder.fromJson(
                Map<String, dynamic>.from(json['active_order'] as Map),
              ),
        favoriteCount: (json['favorite_count'] as num?)?.toInt() ?? 0,
        supportOpenCount: (json['support_open_count'] as num?)?.toInt() ?? 0,
        featuredStocks: ((json['featured_stocks'] as List?) ?? [])
            .map((e) => FeaturedStock.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList(),
      );
}

Future<PatientSummary> fetchPatientSummary() async {
  final json =
      await AuthSession.instance.api.getJson('mobile/patient/summary/');
  return PatientSummary.fromJson(json);
}
