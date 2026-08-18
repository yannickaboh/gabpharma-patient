import 'auth_session.dart';

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
    required this.name,
    required this.dosage,
    required this.formLabel,
  });

  final String name;
  final String dosage;
  final String formLabel;

  factory CatalogMedication.fromJson(Map<String, dynamic> json) =>
      CatalogMedication(
        name: json['name']?.toString() ?? '',
        dosage: json['dosage']?.toString() ?? '',
        formLabel: json['form_label']?.toString() ?? '',
      );
}

class CatalogPharmacy {
  const CatalogPharmacy({required this.name, required this.zoneLabel});

  final String name;
  final String zoneLabel;

  factory CatalogPharmacy.fromJson(Map<String, dynamic> json) =>
      CatalogPharmacy(
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
  });

  final int id;
  final CatalogMedication medication;
  final CatalogPharmacy pharmacy;
  final int priceFcfa;
  final int quantity;
  final bool isAvailable;

  bool get inStock => isAvailable && quantity > 0;

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
