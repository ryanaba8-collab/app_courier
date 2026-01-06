import 'package:dio/dio.dart';

class BanAddress {
  final String label;
  final String id;
  final double score; // score BAN (0..1 ou +)
  final String? housenumber;
  final String? street;
  final String? city;
  final String? postcode;

  BanAddress({
    required this.label,
    required this.id,
    required this.score,
    this.housenumber,
    this.street,
    this.city,
    this.postcode,
  });
}

class BanApi {
  final Dio _dio;

  BanApi(this._dio);

  /// Reverse geocoding via BAN
  /// Doc: https://api-adresse.data.gouv.fr
  Future<BanAddress?> reverse({
    required double lat,
    required double lon,
  }) async {
    final res = await _dio.get(
      'https://api-adresse.data.gouv.fr/reverse/',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'limit': 1,
      },
    );

    final features = (res.data['features'] as List?) ?? const [];
    if (features.isEmpty) return null;

    final props = features.first['properties'] as Map<String, dynamic>;
    return BanAddress(
      label: (props['label'] ?? '') as String,
      id: (props['id'] ?? '') as String,
      score: ((props['score'] ?? 0.0) as num).toDouble(),
      housenumber: props['housenumber']?.toString(),
      street: props['street']?.toString(),
      city: props['city']?.toString(),
      postcode: props['postcode']?.toString(),
    );
  }
}
