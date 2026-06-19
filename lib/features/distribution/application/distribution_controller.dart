import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/gps/gps_stabilizer.dart';
import '../../../core/network/dio_provider.dart';

import '../infrastructure/ban_api.dart';
import '../infrastructure/ors_api.dart';
import 'passage_detector.dart';
import 'stop_detector.dart';

enum DistributionRunState { running, paused }

class DistributionState {
  final DistributionRunState runState;
  final bool hasStarted;
  final int totalDelivered;

  final String? lastAddressLabel;

  final int? pendingDepositId;
  final String? pendingAddressLabel;

  final LatLng? current;
  final List<LatLng> route;

  final int? currentTourId;

  const DistributionState({
    required this.runState,
    required this.hasStarted,
    required this.totalDelivered,
    this.lastAddressLabel,
    this.pendingDepositId,
    this.pendingAddressLabel,
    this.current,
    required this.route,
    this.currentTourId,
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
    int? currentTourId,
    bool clearPending = false,
    bool clearTour = false,
  }) {
    return DistributionState(
      runState: runState ?? this.runState,
      hasStarted: hasStarted ?? this.hasStarted,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      lastAddressLabel: lastAddressLabel ?? this.lastAddressLabel,
      pendingDepositId:
          clearPending ? null : (pendingDepositId ?? this.pendingDepositId),
      pendingAddressLabel: clearPending
          ? null
          : (pendingAddressLabel ?? this.pendingAddressLabel),
      current: current ?? this.current,
      route: route ?? this.route,
      currentTourId: clearTour ? null : (currentTourId ?? this.currentTourId),
    );
  }
}

class DistributionController extends StateNotifier<DistributionState> {
  StreamSubscription<Position>? _sub;

  final PassageDetector _passageDetector = PassageDetector();
  final GpsStabilizer _gpsStabilizer = GpsStabilizer();

  final BanApi _ban;
  final OrsApi _ors;
  final AppDb _db;

  String? _lastSavedLabel;
  DateTime? _lastSavedAt;
  LatLng? _lastSavedPos;

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
          currentTourId: null,
        ));

  Future<void> startOrResume() async {
    await _ensurePermissions();

    var tourId = state.currentTourId;

    if (tourId == null) {
      final now = DateTime.now();
      tourId = await _db.createTour(
        startedAt: now,
        name: 'Tournée ${now.toIso8601String()}',
      );
    }

    state = state.copyWith(
      runState: DistributionRunState.running,
      hasStarted: true,
      currentTourId: tourId,
    );

    await _sub?.cancel();

    _gpsStabilizer.resetAll();
    _passageDetector.resetAll();

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((pos) {
      if (state.runState != DistributionRunState.running) return;

      final stable = _gpsStabilizer.ingest(
        pos.latitude,
        pos.longitude,
        pos.accuracy,
      );

      if (stable == null) return;

      final speed = (pos.speed.isFinite && pos.speed >= 0) ? pos.speed : 0.0;

      final fix = GpsFix(
        lat: stable.lat,
        lon: stable.lon,
        accuracy: pos.accuracy,
        speed: speed,
        t: pos.timestamp,
      );

      final cur = LatLng(fix.lat, fix.lon);
      state = state.copyWith(current: cur);

      _appendRoutePoint(cur, fix.accuracy);

      final passage = _passageDetector.ingest(fix);
      if (passage != null) {
        _handlePassage(passage);
      }
    });
  }

  Future<void> pause() async {
    state = state.copyWith(runState: DistributionRunState.paused);

    _gpsStabilizer.resetAll();
    _passageDetector.resetAll();

    await _sub?.cancel();
    _sub = null;
  }

  Future<void> endTour() async {
    final tourId = state.currentTourId;

    await pause();

    if (tourId != null) {
      await _db.closeTour(tourId, DateTime.now());
    }

    _lastSavedLabel = null;
    _lastSavedAt = null;
    _lastSavedPos = null;

    state = state.copyWith(
      hasStarted: false,
      totalDelivered: 0,
      lastAddressLabel: null,
      pendingDepositId: null,
      pendingAddressLabel: null,
      current: null,
      route: const [],
      clearPending: true,
      clearTour: true,
    );
  }

  Future<void> markNoAd() async {
    final tourId = state.currentTourId;
    final last = await _db.getLastDeposit(tourId: tourId);

    if (last != null) {
      final age = DateTime.now().difference(last.createdAt);

      if (age.inMinutes <= 3) {
        await _db.setNoAdById(last.id, true);
        return;
      }
    }

    final cur = state.current;
    if (cur == null) return;

    final depositId = await _db.insertDeposit(
      createdAt: DateTime.now(),
      lat: cur.latitude,
      lon: cur.longitude,
      accuracy: 50,
      addressLabel: state.lastAddressLabel,
      deliveryStatus: 2,
      buildingSuspected: false,
      groupId: null,
      tourId: tourId,
    );

    await _db.setNoAdById(depositId, true);
  }

  Future<void> confirmPendingDeposit(int newStatus) async {
    final id = state.pendingDepositId;
    if (id == null) return;

    await _db.updateDepositStatusById(id, newStatus);

    if (newStatus == 0) {
      state = state.copyWith(totalDelivered: state.totalDelivered + 1);
    }

    state = state.copyWith(clearPending: true);
  }

  void _appendRoutePoint(LatLng cur, double acc) {
    if (acc > 60) return;

    final r = state.route;
    if (r.isEmpty) {
      state = state.copyWith(route: [cur]);
      return;
    }

    final last = r.last;
    final meters = const Distance().as(
      LengthUnit.Meter,
      last,
      cur,
    );

    if (meters >= 3) {
      state = state.copyWith(route: [...r, cur]);
    }
  }

  Future<void> _handlePassage(PassageEvent p) async {
    final tourId = state.currentTourId;
    final forceReview = p.accuracy > 30;

    if (_lastSavedPos != null) {
      final d = const Distance().as(
        LengthUnit.Meter,
        _lastSavedPos!,
        LatLng(p.lat, p.lon),
      );

      if (d < 8 &&
          _lastSavedAt != null &&
          DateTime.now().difference(_lastSavedAt!) <
              const Duration(seconds: 8)) {
        return;
      }
    }

    try {
      final addr = await _ban.reverse(lat: p.lat, lon: p.lon);
      final label = addr?.label;

      state = state.copyWith(lastAddressLabel: label);

      if (label != null &&
          _lastSavedLabel != null &&
          label == _lastSavedLabel) {
        final dt = _lastSavedAt == null
            ? 9999
            : DateTime.now().difference(_lastSavedAt!).inSeconds;

        if (dt < 45) return;
      }

      final suspectedBuilding = !forceReview &&
          p.accuracy <= 35 &&
          label != null &&
          label.contains(',');

      if (suspectedBuilding) {
        final depositId = await _db.insertDeposit(
          createdAt: DateTime.now(),
          lat: p.lat,
          lon: p.lon,
          accuracy: p.accuracy,
          addressLabel: label,
          deliveryStatus: 2,
          buildingSuspected: true,
          tourId: tourId,
        );

        state = state.copyWith(
          pendingDepositId: depositId,
          pendingAddressLabel: label,
        );
      } else {
        final status = forceReview ? 2 : 0;

        await _db.insertDeposit(
          createdAt: DateTime.now(),
          lat: p.lat,
          lon: p.lon,
          accuracy: p.accuracy,
          addressLabel: label,
          deliveryStatus: status,
          buildingSuspected: false,
          tourId: tourId,
        );

        if (status == 0) {
          state = state.copyWith(totalDelivered: state.totalDelivered + 1);
        }

        _lastSavedLabel = label;
        _lastSavedAt = DateTime.now();
        _lastSavedPos = LatLng(p.lat, p.lon);
      }
    } catch (_) {
      await _db.insertDeposit(
        createdAt: DateTime.now(),
        lat: p.lat,
        lon: p.lon,
        accuracy: p.accuracy,
        addressLabel: null,
        deliveryStatus: 2,
        buildingSuspected: false,
        tourId: tourId,
      );

      _lastSavedLabel = null;
      _lastSavedAt = DateTime.now();
      _lastSavedPos = LatLng(p.lat, p.lon);
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

final orsApiProvider = Provider<OrsApi>((ref) {
  final dio = ref.read(dioProvider);
  const apiKey = String.fromEnvironment('ORS_API_KEY', defaultValue: '');
  return OrsApi(dio, apiKey: apiKey);
});

final distributionControllerProvider =
    StateNotifierProvider<DistributionController, DistributionState>(
  (ref) => DistributionController(
    ref.read(dioProvider),
    ref.read(appDbProvider),
    ref.read(orsApiProvider),
  ),
);