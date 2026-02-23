import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
const String orsApikey="eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjVlMThiZWEyMGMxZTRmMmFhNmFmYjIwMWM0ZGY0YThhIiwiaCI6Im11cm11cjY0In0=";
class OrsApi {
  
  final Dio _dio;
  final String apiKey;

  OrsApi(this._dio, {required this.apiKey});

  Future<List<List<double>>> directions({
    required List<List<double>> coordinates, // [[lon,lat], [lon,lat]]
  }) async {
    final url =
        'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';

    final response = await _dio.post(
      url,
      options: Options(
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'coordinates': coordinates,
      },
    );

    final features = response.data['features'] as List;
    final geometry = features.first['geometry'];
    final coords = geometry['coordinates'] as List;

    return coords
        .map((e) => [(e[0] as num).toDouble(), (e[1] as num).toDouble()])
        .toList();
  }
  
}
final orsApiProvider = Provider<OrsApi>((ref) {
    final dio =ref.read(dioProvider);
  return OrsApi(
    dio,
    apiKey: orsApikey,
  );
});