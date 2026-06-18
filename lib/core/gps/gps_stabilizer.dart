import 'dart:math';

class StableGps {
  final double lat;
  final double lon;
  final double accuracy;

  StableGps(this.lat, this.lon, this.accuracy);
}

class GpsStabilizer {
  static const double maxAccuracy = 25; // ignorer mauvais GPS
  static const double maxJump = 15; // ignorer saut GPS

  final List<StableGps> _buffer = [];

  StableGps? ingest(double lat, double lon, double accuracy) {
    // 1️⃣ filtre accuracy
    if (accuracy > maxAccuracy) return null;

    final point = StableGps(lat, lon, accuracy);

    // 2️⃣ filtre saut GPS
    if (_buffer.isNotEmpty) {
      final prev = _buffer.last;

      final d = _distance(prev.lat, prev.lon, lat, lon);

      if (d > maxJump) {
        return null;
      }
    }

    _buffer.add(point);

    if (_buffer.length > 5) {
      _buffer.removeAt(0);
    }

    // 3️⃣ moyenne glissante
    double latSum = 0;
    double lonSum = 0;

    for (final p in _buffer) {
      latSum += p.lat;
      lonSum += p.lon;
    }

    final latAvg = latSum / _buffer.length;
    final lonAvg = lonSum / _buffer.length;

    return StableGps(latAvg, lonAvg, accuracy);
  }

  double _distance(lat1, lon1, lat2, lon2) {
    const r = 6371000;

    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) *
            cos(_rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return r * c;
  }

  double _rad(double deg) => deg * pi / 180;
  void resetAll() {
  _buffer.clear();
}
}