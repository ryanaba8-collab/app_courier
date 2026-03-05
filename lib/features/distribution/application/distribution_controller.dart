import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/network/dio_provider.dart';

import '../infrastructure/ban_api.dart';
import '../infrastructure/ors_api.dart';
import 'stop_detector.dart'; // pour GpsFix
import 'passage_detector.dart';

enum DistributionRunState { running, paused }

// deliveryStatus: 0=livré, 1=pas accès, 2=à vérifier
class DistributionState {
  final DistributionRunState runState;

  /// pour afficher Commencer/Reprendre correctement
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

  final PassageDetector _passageDetector = PassageDetector();

  final BanApi _ban;
  final OrsApi _ors;
  final AppDb _db;

  // Anti-doublon simple (mémoire)
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
        ));

  Future<void> startOrResume() async {
    state = state.copyWith(
      runState: DistributionRunState.running,
      hasStarted: true,
    );

    await _ensurePermissions();

    await _sub?.cancel();
    _passageDetector.resetAll();

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

      // ✅ update position live
      final cur = LatLng(fix.lat, fix.lon);
      state = state.copyWith(current: cur);

      // ✅ route "type apple watch" (petit filtrage)
      _appendRoutePoint(cur, fix.accuracy);

      // ✅ détection passage (au lieu d’un stop)
      final passage = _passageDetector.ingest(fix);
      if (passage != null) {
        _handlePassage(passage);
      }
    });
  }

  Future<void> pause() async {
    state = state.copyWith(runState: DistributionRunState.paused);
    await _sub?.cancel();
    _sub = null;
    _passageDetector.resetAll();
  }

  /// FIN DE TOURNÉE : stop + reset UI (bouton redevient "Commencer")
  Future<void> endTour() async {
    await pause();

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
    );
  }
Future<void> markNoAd() async {
  // 1) Tag le dernier dépôt si récent
  final last = await _db.getLastDeposit();

  if (last != null) {
    final age = DateTime.now().difference(last.createdAt);

    // si le dernier dépôt date de moins de 3 minutes -> on le marque noAd
    if (age.inMinutes <= 3) {
      await _db.setNoAdById(last.id, true);
      return;
    }
  }

  // 2) Sinon on crée un dépôt noAd basé sur la position actuelle
  final cur = state.current;
  if (cur == null) return;

  final depositId = await _db.insertDeposit(
    createdAt: DateTime.now(),
    lat: cur.latitude,
    lon: cur.longitude,
    accuracy: 50, // valeur fallback simple (pas de debug)
    addressLabel: state.lastAddressLabel,
    deliveryStatus: 2, // "à vérifier" par défaut
    buildingSuspected: false,
    groupId: null,
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

    state = state.copyWith(
      pendingDepositId: null,
      pendingAddressLabel: null,
    );
  }

  void _appendRoutePoint(LatLng cur, double acc) {
    // trop imprécis => on n’enregistre pas dans le tracé
    if (acc > 60) return;

    final r = state.route;
    if (r.isEmpty) {
      state = state.copyWith(route: [cur]);
      return;
    }

    final last = r.last;
    final meters = const Distance().as(LengthUnit.Meter, last, cur);

    // évite de spammer la liste (ajoute tous les ~3m)
    if (meters >= 3) {
      state = state.copyWith(route: [...r, cur]);
    }
  }

  Future<void> _handlePassage(PassageEvent p) async {
    // Quand accuracy > 30m : tu veux quand même enregistrer MAIS À VÉRIFIER
    final forceReview = p.accuracy > 30;

    // Anti-doublon par distance (utile si BAN rate)
    if (_lastSavedPos != null) {
      final d = const Distance().as(
        LengthUnit.Meter,
        _lastSavedPos!,
        LatLng(p.lat, p.lon),
      );
      // Si on vient d’enregistrer très près, on laisse BAN gérer via label,
      // mais on évite le spam si BAN ne répond pas.
      if (d < 8 && _lastSavedAt != null && DateTime.now().difference(_lastSavedAt!) < const Duration(seconds: 8)) {
        return;
      }
    }

    try {
      // Reverse BAN (adresse)
      final addr = await _ban.reverse(lat: p.lat, lon: p.lon);
      final label = addr?.label;

      state = state.copyWith(lastAddressLabel: label);

      // Anti-doublon par adresse (le plus important)
      if (label != null && _lastSavedLabel != null && label == _lastSavedLabel) {
        final dt = _lastSavedAt == null ? 9999 : DateTime.now().difference(_lastSavedAt!).inSeconds;
        if (dt < 45) {
          return; // même adresse trop proche dans le temps
        }
      }

      // Heuristique simple "immeuble probable" (si GPS bon)
      final suspectedBuilding = !forceReview &&
          (p.accuracy <= 35) &&
          (label != null) &&
          label.contains(',');

      if (suspectedBuilding) {
        // Par défaut "À vérifier" (2) + modal
        final depositId = await _db.insertDeposit(
          createdAt: DateTime.now(),
          lat: p.lat,
          lon: p.lon,
          accuracy: p.accuracy,
          addressLabel: label,
          deliveryStatus: 2,
          buildingSuspected: true,
        );

        state = state.copyWith(
          pendingDepositId: depositId,
          pendingAddressLabel: label,
        );
      } else {
        // Ici: si accuracy > 30 => À vérifier, sinon Livré
        final status = forceReview ? 2 : 0;

        await _db.insertDeposit(
          createdAt: DateTime.now(),
          lat: p.lat,
          lon: p.lon,
          accuracy: p.accuracy,
          addressLabel: label,
          deliveryStatus: status,
          buildingSuspected: false,
        );

        if (status == 0) {
          state = state.copyWith(totalDelivered: state.totalDelivered + 1);
        }

        _lastSavedLabel = label;
        _lastSavedAt = DateTime.now();
        _lastSavedPos = LatLng(p.lat, p.lon);
      }
    } catch (_) {
      // BAN KO -> À vérifier
      await _db.insertDeposit(
        createdAt: DateTime.now(),
        lat: p.lat,
        lon: p.lon,
        accuracy: p.accuracy,
        addressLabel: null,
        deliveryStatus: 2,
        buildingSuspected: false,
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

/// Provider ORS (si tu l’as déjà, garde le tien)
final orsApiProvider = Provider<OrsApi>((ref) {
  final dio = ref.read(dioProvider);
  // ⚠️ Remplace par ta vraie clé (ou garde ta constante existante)
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