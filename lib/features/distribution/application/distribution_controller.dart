import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';

import '../infrastructure/ban_api.dart';
import '../infrastructure/ors_api.dart';
import 'stop_detector.dart';
import '../../../core/network/dio_provider.dart';


enum DistributionRunState { running, paused }

// deliveryStatus: 0=livré, 1=pas accès, 2=à vérifier
class DistributionState {
  final DistributionRunState runState;

  /// ✅ pour afficher Commencer/Reprendre correctement
  final bool hasStarted;

  /// compteur "livré" uniquement
  final int totalDelivered;

  final String? lastAddressLabel;

  /// confirmation immeuble
  final int? pendingDepositId;
  final String? pendingAddressLabel;

  /// live map
  final LatLng? current;
  final List<LatLng> route;

  const DistributionState({
    required this.runState,
    required this.hasStarted,
    required this.totalDelivered,
    this.lastAddressLabel,
    this.pendingDepositId,
    this.pendingAddressLabel,
    this.current,
    required this.route,
  });

  DistributionState copyWith({
    DistributionRunState? runState,
    bool? hasStarted,
    int? totalDelivered,
    String? lastAddressLabel,
    int? pendingDepositId,
    String? pendingAddressLabel,
    LatLng? current,
    List<LatLng>? route,
  }) {
    return DistributionState(
      runState: runState ?? this.runState,
      hasStarted: hasStarted ?? this.hasStarted,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      lastAddressLabel: lastAddressLabel ?? this.lastAddressLabel,
      pendingDepositId: pendingDepositId ?? this.pendingDepositId,
      pendingAddressLabel: pendingAddressLabel ?? this.pendingAddressLabel,
      current: current ?? this.current,
      route: route ?? this.route,
    );
  }
}

class DistributionController extends StateNotifier<DistributionState> {
  StreamSubscription<Position>? _sub;
  final StopDetector _detector = StopDetector();

  final BanApi _ban;
  final OrsApi _ors;
  final AppDb _db;

  DistributionController(Dio dio, AppDb db, OrsApi ors)
      : _ban = BanApi(dio),
        _db = db,
        _ors = ors,
        super(const DistributionState(
          runState: DistributionRunState.paused,
          hasStarted: false,
          totalDelivered: 0,
          lastAddressLabel: null,
          pendingDepositId: null,
          pendingAddressLabel: null,
          current: null,
          route: [],
        ));

  Future<void> startOrResume() async {
    // ✅ démarre
    state = state.copyWith(
      runState: DistributionRunState.running,
      hasStarted: true,
    );

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

      // ✅ MAJ position live
      final cur = LatLng(pos.latitude, pos.longitude);
      state = state.copyWith(current: cur);

      // ⚠️ si tu veux recalculer route souvent : à faire avec prudence (coût ORS)
      // _recomputeRouteIfNeeded(); // optionnel

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

  /// ✅ FIN DE TOURNÉE : stop + reset UI (bouton redevient "Commencer")
  Future<void> endTour() async {
    await pause();

    state = state.copyWith(
      hasStarted: false,
      totalDelivered: 0,
      lastAddressLabel: null,
      pendingDepositId: null,
      pendingAddressLabel: null,
      current: null,
      route: const [],
    );
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

  Future<void> _handleStop(StopEvent stop) async {
    try {
      // Reverse BAN
      final addr = await _ban.reverse(lat: stop.latMedian, lon: stop.lonMedian);
      final label = addr?.label;

      state = state.copyWith(lastAddressLabel: label);

      // Heuristique simple: "immeuble probable"
      final suspectedBuilding =
          (stop.accuracyMedian <= 35) && (label != null) && label.contains(',');

      if (suspectedBuilding) {
        // Par défaut "À vérifier" (2)
        final depositId = await _db.insertDeposit(
          createdAt: DateTime.now(),
          lat: stop.latMedian,
          lon: stop.lonMedian,
          accuracy: stop.accuracyMedian,
          addressLabel: label,
          deliveryStatus: 2,
          buildingSuspected: true,
        );

        // Déclenche la question UI
        state = state.copyWith(
          pendingDepositId: depositId,
          pendingAddressLabel: label,
        );
      } else {
        // Livré automatiquement
        await _db.insertDeposit(
          createdAt: DateTime.now(),
          lat: stop.latMedian,
          lon: stop.lonMedian,
          accuracy: stop.accuracyMedian,
          addressLabel: label,
          deliveryStatus: 0,
          buildingSuspected: false,
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

    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
      throw Exception('Permission localisation refusée');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// ⚠️ Si ton provider ORS n’a pas ce nom, remplace `orsApiProvider` ici.
final distributionControllerProvider =
    StateNotifierProvider<DistributionController, DistributionState>(
  (ref) => DistributionController(
    ref.read(dioProvider),
    ref.read(appDbProvider),
    ref.read(orsApiProvider),
  ),
);



