// lib/features/distribution/application/distribution_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../main.dart'; // dioProvider (si rouge, dis-moi et on le déplacera dans core/network)
import '../infrastructure/ban_api.dart';
import 'stop_detector.dart';

enum DistributionRunState { running, paused }

// deliveryStatus: 0=livré, 1=pas accès, 2=à vérifier
class DistributionState {
  final DistributionRunState runState;

  // compteur "livré" uniquement
  final int totalDelivered;

  final String? lastAddressLabel;

  // confirmation immeuble
  final int? pendingDepositId;
  final String? pendingAddressLabel;

  const DistributionState({
    required this.runState,
    required this.totalDelivered,
    this.lastAddressLabel,
    this.pendingDepositId,
    this.pendingAddressLabel,
  });

  DistributionState copyWith({
    DistributionRunState? runState,
    int? totalDelivered,
    String? lastAddressLabel,
    int? pendingDepositId,
    String? pendingAddressLabel,
  }) {
    return DistributionState(
      runState: runState ?? this.runState,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      lastAddressLabel: lastAddressLabel ?? this.lastAddressLabel,
      pendingDepositId: pendingDepositId ?? this.pendingDepositId,
      pendingAddressLabel: pendingAddressLabel ?? this.pendingAddressLabel,
    );
  }
}

class DistributionController extends StateNotifier<DistributionState> {
  StreamSubscription<Position>? _sub;
  final StopDetector _detector = StopDetector();

  final BanApi _ban;
  final AppDb _db;

  DistributionController(Dio dio, AppDb db)
      : _ban = BanApi(dio),
        _db = db,
        super(const DistributionState(
          runState: DistributionRunState.paused,
          totalDelivered: 0,
          lastAddressLabel: null,
          pendingDepositId: null,
          pendingAddressLabel: null,
        ));

  Future<void> startOrResume() async {
    state = state.copyWith(runState: DistributionRunState.running);

    await _ensurePermissions();

    await _sub?.cancel();
    _detector.resetAll();

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((pos) {
      if (state.runState != DistributionRunState.running) return;

      final fix = GpsFix(
        lat: pos.latitude,
        lon: pos.longitude,
        accuracy: pos.accuracy,
        speed: (pos.speed.isFinite && pos.speed >= 0) ? pos.speed : 0.0,
        t: pos.timestamp,
      );

      final stop = _detector.ingest(fix);
      if (stop != null) {
        _handleStop(stop);
      }
    });
  }

  Future<void> pause() async {
    state = state.copyWith(runState: DistributionRunState.paused);
    await _sub?.cancel();
    _sub = null;
    _detector.resetAll();
  }

  Future<void> confirmPendingDeposit(int newStatus) async {
    final id = state.pendingDepositId;
    if (id == null) return;

    await _db.updateDepositStatusById(id, newStatus);

    // Si livré -> on comptabilise
    if (newStatus == 0) {
      state = state.copyWith(totalDelivered: state.totalDelivered + 1);
    }

    // Clear pending
    state = state.copyWith(
      pendingDepositId: null,
      pendingAddressLabel: null,
    );
  }

  // ---- Grouping helpers (immeubles) ----

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // rayon Terre en m
    final dLat = (lat2 - lat1) * 0.017453292519943295;
    final dLon = (lon2 - lon1) * 0.017453292519943295;

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * 0.017453292519943295) *
            cos(lat2 * 0.017453292519943295) *
            (sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Future<int> _getOrCreateGroupId({
    required double lat,
    required double lon,
    required String? addressLabel,
  }) async {
    const maxDist = 20.0; // mètres
    const maxAge = Duration(minutes: 3);

    final now = DateTime.now();
    final since = now.subtract(maxAge);

    final recent = await _db.getRecentGroups(since);

    int? bestId;
    double bestDist = 1e18;

    for (final g in recent) {
      // si label connu, on privilégie les labels identiques
      if (addressLabel != null && g.addressLabel != null) {
        if (g.addressLabel != addressLabel) continue;
      }

      final d = _distanceMeters(lat, lon, g.centerLat, g.centerLon);
      if (d <= maxDist && d < bestDist) {
        bestDist = d;
        bestId = g.id;
      }
    }

    if (bestId != null) return bestId;

    return _db.createDeliveryGroup(
      createdAt: now,
      centerLat: lat,
      centerLon: lon,
      addressLabel: addressLabel,
    );
  }

  // ---- Stop handling ----

  Future<void> _handleStop(StopEvent stop) async {
    try {
      final addr = await _ban.reverse(lat: stop.latMedian, lon: stop.lonMedian);
      final label = addr?.label;

      state = state.copyWith(lastAddressLabel: label);

      // Heuristique simple: "immeuble probable"
      final suspectedBuilding =
          (stop.accuracyMedian <= 35) && (label != null) && label.contains(',');

      if (suspectedBuilding) {
        final groupId = await _getOrCreateGroupId(
          lat: stop.latMedian,
          lon: stop.lonMedian,
          addressLabel: label,
        );

        final depositId = await _db.insertDeposit(
          createdAt: DateTime.now(),
          lat: stop.latMedian,
          lon: stop.lonMedian,
          accuracy: stop.accuracyMedian,
          addressLabel: label,
          deliveryStatus: 2, // à vérifier par défaut
          buildingSuspected: true,
          groupId: groupId, // ✅ groupement
        );

        // Déclenche la question UI
        state = state.copyWith(
          pendingDepositId: depositId,
          pendingAddressLabel: label,
        );
      } else {
        // Maison / pas immeuble -> Livré automatiquement
        await _db.insertDeposit(
          createdAt: DateTime.now(),
          lat: stop.latMedian,
          lon: stop.lonMedian,
          accuracy: stop.accuracyMedian,
          addressLabel: label,
          deliveryStatus: 0,
          buildingSuspected: false,
          groupId: null,
        );

        state = state.copyWith(totalDelivered: state.totalDelivered + 1);
      }
    } catch (_) {
      // BAN KO -> À vérifier
      final depositId = await _db.insertDeposit(
        createdAt: DateTime.now(),
        lat: stop.latMedian,
        lon: stop.lonMedian,
        accuracy: stop.accuracyMedian,
        addressLabel: null,
        deliveryStatus: 2,
        buildingSuspected: false,
        groupId: null,
      );

      state = state.copyWith(
        pendingDepositId: depositId,
        pendingAddressLabel: null,
      );
    }
  }

  Future<void> _ensurePermissions() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Services de localisation désactivés');
    }

    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }

    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      throw Exception('Permission localisation refusée');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final distributionControllerProvider =
    StateNotifierProvider<DistributionController, DistributionState>(
  (ref) => DistributionController(
    ref.read(dioProvider),
    ref.read(appDbProvider),
  ),
);
