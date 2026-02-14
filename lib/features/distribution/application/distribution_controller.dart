// lib/features/distribution/application/distribution_controller.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../main.dart'; // dioProvider
import '../infrastructure/ban_api.dart';
import '../infrastructure/ors_api.dart';
import 'stop_detector.dart';

enum DistributionRunState { running, paused }

// deliveryStatus: 0=livré, 1=pas accès, 2=à vérifier
class DistributionState {
    // TRACK COMPLET (toute la tournée)
  final List<LatLng> fullTrack;
  final double totalDistanceMeters;
  final Duration totalDuration;
  final DateTime? sessionStart;

  final DistributionRunState runState;

  // compteur "livré" uniquement
  final int totalDelivered;

  final String? lastAddressLabel;

  // confirmation immeuble
  final int? pendingDepositId;
  final String? pendingAddressLabel;

  // MAP LIVE
  final LatLng? current; // position actuelle
  final List<LatLng> route; // polyline ORS

  const DistributionState({
        this.fullTrack = const [],
    this.totalDistanceMeters = 0,
    this.totalDuration = Duration.zero,
    this.sessionStart,

    required this.runState,
    required this.totalDelivered,
    this.lastAddressLabel,
    this.pendingDepositId,
    this.pendingAddressLabel,
    this.current,
    this.route = const [],
  });

  DistributionState copyWith({
        List<LatLng>? fullTrack,
    double? totalDistanceMeters,
    Duration? totalDuration,
    DateTime? sessionStart,

    DistributionRunState? runState,
    int? totalDelivered,
    String? lastAddressLabel,
    int? pendingDepositId,
    String? pendingAddressLabel,
    LatLng? current,
    List<LatLng>? route,
  }) {
    return DistributionState(
            fullTrack: fullTrack ?? this.fullTrack,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalDuration: totalDuration ?? this.totalDuration,
      sessionStart: sessionStart ?? this.sessionStart,

      runState: runState ?? this.runState,
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

  // anti-spam routing
  DateTime? _lastRouteAt;
  LatLng? _lastRouteFrom;
  bool _routingBusy = false;

  DistributionController(Dio dio, AppDb db, OrsApi ors)
      : _ban = BanApi(dio),
        _db = db,
        _ors = ors,
        super(const DistributionState(
          runState: DistributionRunState.paused,
          totalDelivered: 0,
          lastAddressLabel: null,
          pendingDepositId: null,
          pendingAddressLabel: null,
          current: null,
          route: [],
        ));

  Future<void> startOrResume() async {
    state = state.copyWith(runState: DistributionRunState.running);
    // ✅ Démarre une session "tournée"
    state = state.copyWith(
      sessionStart: DateTime.now(),
      fullTrack: const [],
      totalDistanceMeters: 0,
      totalDuration: Duration.zero,
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
      // ✅ TRACK COMPLET + distance + durée
      final newPoint = LatLng(pos.latitude, pos.longitude);

      final previousTrack = state.fullTrack;
      var newDistance = state.totalDistanceMeters;

      if (previousTrack.isNotEmpty) {
        newDistance += const Distance().as(
          LengthUnit.Meter,
          previousTrack.last,
          newPoint,
        );
      }

      final start = state.sessionStart ?? DateTime.now();
      final newDuration = DateTime.now().difference(start);

      state = state.copyWith(
        fullTrack: [...previousTrack, newPoint],
        totalDistanceMeters: newDistance,
        totalDuration: newDuration,
      );

      // ✅ position live (sert à la carte)
      final cur = LatLng(pos.latitude, pos.longitude);
      state = state.copyWith(current: cur);

      // ✅ recalcul route (anti-spam)
      _recomputeRouteIfNeeded();

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

    // reset route
    _lastRouteAt = null;
    _lastRouteFrom = null;
    _routingBusy = false;
    state = state.copyWith(route: const []);
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

    // après une confirmation, on peut recalculer la route
    _lastRouteAt = null;
    _lastRouteFrom = null;
    _recomputeRouteIfNeeded(force: true);
  }

  Future<void> _handleStop(StopEvent stop) async {
    try {
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
    } finally {
      // après un nouveau dépôt, on autorise un recalcul rapide
      _lastRouteAt = null;
      _lastRouteFrom = null;
      _recomputeRouteIfNeeded(force: true);
    }
  }

  /// Recalcule une route ORS depuis la position actuelle vers le "prochain point utile".
  /// - Priorité: ⚠️ (2) puis ❌ (1)
  /// - Choisit le plus proche (distance GPS)
  /// Anti-spam: au max toutes les 20s ou si déplacement > 80m (sauf force=true)
  Future<void> _recomputeRouteIfNeeded({bool force = false}) async {
    final cur = state.current;
    if (cur == null) return;

    // pas de route si on est en pause
    if (state.runState != DistributionRunState.running) return;

    final now = DateTime.now();

    if (!force) {
      final lastAt = _lastRouteAt;
      final lastFrom = _lastRouteFrom;

      final timeOk = lastAt == null || now.difference(lastAt).inSeconds >= 20;

      var movedOk = true;
      if (lastFrom != null) {
        final dist = const Distance().as(LengthUnit.Meter, lastFrom, cur);
        movedOk = dist >= 80;
      }

      if (!(timeOk || movedOk)) return;
    }

    if (_routingBusy) return;
    _routingBusy = true;

    _lastRouteAt = now;
    _lastRouteFrom = cur;

    try {
      // On récupère les dépôts (pour l'instant simple: on prend tout)
      final rows = await _db.watchAllDeposits().first;
      if (rows.isEmpty) {
        state = state.copyWith(route: const []);
        return;
      }

      // Cibles: à vérifier puis pas accès
      final candidatesReview = rows.where((d) => d.deliveryStatus == 2).toList();
      final candidatesNoAccess =
          rows.where((d) => d.deliveryStatus == 1).toList();

      List<Deposit> candidates = candidatesReview.isNotEmpty
          ? candidatesReview
          : (candidatesNoAccess.isNotEmpty ? candidatesNoAccess : const []);

      // Si aucune cible (tout livré), on ne trace rien
      if (candidates.isEmpty) {
        state = state.copyWith(route: const []);
        return;
      }

      // Choix: le plus proche de la position actuelle
      candidates.sort((a, b) {
        final da = const Distance().as(
          LengthUnit.Meter,
          cur,
          LatLng(a.lat, a.lon),
        );
        final dbb = const Distance().as(
          LengthUnit.Meter,
          cur,
          LatLng(b.lat, b.lon),
        );
        return da.compareTo(dbb);
      });

      final dest = LatLng(candidates.first.lat, candidates.first.lon);

      // Appel ORS -> geojson: liste de [lon,lat]
      final coords = await _ors.directions(
        coordinates: [
          [cur.longitude, cur.latitude],
          [dest.longitude, dest.latitude],
        ],
      );

      // Convert -> LatLng (lat,lon)
      final poly = coords.map((e) => LatLng(e[1], e[0])).toList();
      state = state.copyWith(route: poly);
    } catch (_) {
      // réseau/quota/clé -> on vide la route pour éviter des erreurs UI
      state = state.copyWith(route: const []);
    } finally {
      _routingBusy = false;
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

final distributionControllerProvider =
    StateNotifierProvider<DistributionController, DistributionState>(
  (ref) {
    final dio = ref.read(dioProvider);
    final db = ref.read(appDbProvider);

    // clé ORS via: flutter run --dart-define=ORS_KEY=xxxxx
    final orsKey = const String.fromEnvironment('ORS_KEY');

    return DistributionController(
      dio,
      db,
      OrsApi(dio, apiKey: orsKey),
    );
  },
);
