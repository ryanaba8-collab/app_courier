import 'dart:math';

class GpsFix {
  final double lat;
  final double lon;
  final double accuracy;
  final double speed; // m/s
  final DateTime t;

  GpsFix({
    required this.lat,
    required this.lon,
    required this.accuracy,
    required this.speed,
    required this.t,
  });
}

class StopEvent {
  final DateTime startedAt;
  final DateTime endedAt;
  final double latMedian;
  final double lonMedian;
  final double accuracyMedian;

  StopEvent({
    required this.startedAt,
    required this.endedAt,
    required this.latMedian,
    required this.lonMedian,
    required this.accuracyMedian,
  });
}

class StopDetector {
  // Seuils (à ajuster)
  final double stopSpeed = 0.5; // < 0.5 m/s = arrêt
  final double walkSpeed = 1.0; // > 1.0 m/s = marche
  final Duration minStop = const Duration(seconds: 5);
  final Duration maxStop = const Duration(seconds: 60);
  final Duration cooldown = const Duration(seconds: 18);

  DateTime? _maybeStopAt;
  final List<GpsFix> _stopPoints = [];
  DateTime? _cooldownUntil;
  bool _wasWalkingRecently = false;

  // Garde un petit historique
  final List<GpsFix> _buf = [];

  StopEvent? ingest(GpsFix fix) {
    _pushBuf(fix);

    if (_cooldownUntil != null && fix.t.isBefore(_cooldownUntil!)) {
      return null;
    }

    // Marque si on marchait récemment (dans les ~15-20 dernières secondes)
    _wasWalkingRecently = _hadWalkingLookback(fix.t);

    final isStop = fix.speed < stopSpeed;
    final isWalk = fix.speed > walkSpeed;

    if (_maybeStopAt == null) {
      // On commence à envisager un stop
      if (isStop) {
        _maybeStopAt = fix.t;
        _stopPoints
          ..clear()
          ..add(fix);
      }
      return null;
    }

    // On est dans un stop potentiel
    _stopPoints.add(fix);
    final stopDur = fix.t.difference(_maybeStopAt!);

    // Stop trop long => on ignore
    if (stopDur > maxStop) {
      _reset();
      return null;
    }

    // Si on reprend la marche, on confirme éventuellement
    if (isWalk && stopDur >= minStop) {
      if (_wasWalkingRecently) {
        final event = _buildEvent(_maybeStopAt!, fix.t, _stopPoints);
        _cooldownUntil = fix.t.add(cooldown);
        _reset();
        return event;
      } else {
        _reset();
        return null;
      }
    }

    // Si on repart marcher trop tôt (stop trop court) => ignore
    if (isWalk && stopDur < minStop) {
      _reset();
      return null;
    }

    return null;
  }

  void resetAll() {
    _reset();
    _cooldownUntil = null;
    _buf.clear();
  }

  void _reset() {
    _maybeStopAt = null;
    _stopPoints.clear();
  }

  void _pushBuf(GpsFix fix) {
    _buf.add(fix);
    final cutoff = fix.t.subtract(const Duration(seconds: 25));
    _buf.removeWhere((x) => x.t.isBefore(cutoff));
  }

  bool _hadWalkingLookback(DateTime now) {
    final from = now.subtract(const Duration(seconds: 20));
    final slice = _buf.where((x) => !x.t.isBefore(from)).toList();
    if (slice.isEmpty) return false;
    final walking = slice.where((x) => x.speed > walkSpeed).length;
    return walking >= max(3, (slice.length * 0.3).floor());
  }

  StopEvent _buildEvent(DateTime start, DateTime end, List<GpsFix> pts) {
    final latMed = _median(pts.map((p) => p.lat).toList());
    final lonMed = _median(pts.map((p) => p.lon).toList());
    final accMed = _median(pts.map((p) => p.accuracy).toList());
    return StopEvent(
      startedAt: start,
      endedAt: end,
      latMedian: latMed,
      lonMedian: lonMed,
      accuracyMedian: accMed,
    );
  }

  double _median(List<double> xs) {
    xs.sort();
    final mid = xs.length ~/ 2;
    if (xs.length.isOdd) return xs[mid];
    return (xs[mid - 1] + xs[mid]) / 2.0;
  }
}
