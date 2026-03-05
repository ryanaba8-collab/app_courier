import 'dart:math';

import 'stop_detector.dart'; // pour réutiliser GpsFix

class PassageEvent {
  final DateTime at;
  final double lat;
  final double lon;
  final double accuracy;
  final double speed;

  PassageEvent({
    required this.at,
    required this.lat,
    required this.lon,
    required this.accuracy,
    required this.speed,
  });
}

/// Détecte des "passages" (candidats dépôt) en marchant, sans attendre un arrêt.
/// - Déclenche quand on a parcouru X mètres (X dépend de l'accuracy)
/// - Filtre les gros sauts GPS
/// - Bloque si vitesse trop élevée (voiture)
class PassageDetector {
  // Marche (m/s)
  final double minWalkSpeed = 0.2; // ~0.7 km/h (quasi immobile)
  final double maxWalkSpeed = 2.2; // ~8 km/h (marche rapide)

  // Anti-voiture
  final double carSpeed = 4.0; // ~14.4 km/h
  final Duration carHold = const Duration(seconds: 20);

  // Filtre sauts GPS
  final double minJumpMeters = 60.0;

  // Cooldown minimal entre 2 candidats (évite spam)
  final Duration minCooldown = const Duration(seconds: 4);

  GpsFix? _lastFix;
  DateTime? _carBlockedUntil;

  DateTime? _lastCandidateAt;
  double? _lastCandidateLat;
  double? _lastCandidateLon;

  PassageEvent? ingest(GpsFix fix) {
    // Anti-voiture : si trop vite, on bloque temporairement
    if (fix.speed > carSpeed) {
      _carBlockedUntil = fix.t.add(carHold);
      _lastFix = fix;
      return null;
    }
    if (_carBlockedUntil != null && fix.t.isBefore(_carBlockedUntil!)) {
      _lastFix = fix;
      return null;
    }

    // Doit ressembler à de la marche
    if (fix.speed < minWalkSpeed || fix.speed > maxWalkSpeed) {
      _lastFix = fix;
      return null;
    }

    // Filtre "gros saut"
    if (_lastFix != null) {
      final dt = fix.t.difference(_lastFix!.t).inMilliseconds / 1000.0;
      if (dt > 0) {
        final d = _haversineMeters(
          _lastFix!.lat,
          _lastFix!.lon,
          fix.lat,
          fix.lon,
        );

        // Si saut énorme en peu de temps => on ignore ce point pour déclencher
        final jumpThreshold = max(minJumpMeters, max(_lastFix!.accuracy, fix.accuracy) * 3);
        if (d > jumpThreshold && dt < 6.0) {
          _lastFix = fix;
          return null;
        }
      }
    }

    // Cooldown minimal entre candidats
    if (_lastCandidateAt != null && fix.t.difference(_lastCandidateAt!) < minCooldown) {
      _lastFix = fix;
      return null;
    }

    // Premier point candidat
    if (_lastCandidateLat == null || _lastCandidateLon == null) {
      _lastCandidateLat = fix.lat;
      _lastCandidateLon = fix.lon;
      _lastCandidateAt = fix.t;
      _lastFix = fix;
      return PassageEvent(
        at: fix.t,
        lat: fix.lat,
        lon: fix.lon,
        accuracy: fix.accuracy,
        speed: fix.speed,
      );
    }

    // Distance depuis le dernier candidat
    final distFromLastCandidate = _haversineMeters(
      _lastCandidateLat!,
      _lastCandidateLon!,
      fix.lat,
      fix.lon,
    );

    final threshold = _metersThresholdForAccuracy(fix.accuracy);

    if (distFromLastCandidate >= threshold) {
      _lastCandidateLat = fix.lat;
      _lastCandidateLon = fix.lon;
      _lastCandidateAt = fix.t;
      _lastFix = fix;

      return PassageEvent(
        at: fix.t,
        lat: fix.lat,
        lon: fix.lon,
        accuracy: fix.accuracy,
        speed: fix.speed,
      );
    }

    _lastFix = fix;
    return null;
  }

  void resetAll() {
    _lastFix = null;
    _carBlockedUntil = null;
    _lastCandidateAt = null;
    _lastCandidateLat = null;
    _lastCandidateLon = null;
  }

  /// Seuil adaptatif (mètres) en fonction de l’accuracy :
  /// - GPS très bon => déclenche très souvent
  /// - GPS mauvais => déclenche moins souvent, et on marquera "à vérifier" côté controller
  double _metersThresholdForAccuracy(double acc) {
    if (acc <= 10) return 9;
    if (acc <= 20) return 14;
    if (acc <= 30) return 20;
    // > 30m : on déclenche moins souvent pour éviter le bruit
    return 28;
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);
}