
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';

import '../application/distribution_controller.dart';
import '../application/export_service.dart';

import 'history_page.dart';
import 'live_map_page.dart';

class DistributionPage extends ConsumerStatefulWidget {
  const DistributionPage({super.key});

  @override
  ConsumerState<DistributionPage> createState() => _DistributionPageState();
}

class _DistributionPageState extends ConsumerState<DistributionPage> {
  bool _sheetOpen = false;
  final _exporter = ExportService();

  Future<void> _showBuildingConfirmSheet(String? label) async {
    if (_sheetOpen) return;
    _sheetOpen = true;

    final controller = ref.read(distributionControllerProvider.notifier);

    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Immeuble — Accès ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(label ?? '(adresse inconnue)'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.confirmPendingDeposit(0); // livré
                  },
                  child: const Text('Accès OK → Livré'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.confirmPendingDeposit(1); // pas accès
                  },
                  child: const Text('Accès impossible → Non livré'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.confirmPendingDeposit(2); // à vérifier
                  },
                  child: const Text('Je ne sais pas → À vérifier'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Si tu fermes cette fenêtre, ça restera “À vérifier”.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );

    _sheetOpen = false;
  }

  /// ✅ Export + reset tournée (bouton redevient Commencer)
  Future<void> _endTour() async {
    final db = ref.read(appDbProvider);
    final controller = ref.read(distributionControllerProvider.notifier);

    // récupère tous les dépôts
    final rows = await db.select(db.deposits).get();

    // Choix CSV/PDF (même si vide on peut reset)
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_view),
              title: const Text('Exporter CSV'),
              onTap: () => Navigator.pop(ctx, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exporter PDF'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Ne pas exporter (juste finir)'),
              onTap: () => Navigator.pop(ctx, 'none'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null) return;

    // Export si demandé ET si on a des dépôts
    if (action != 'none') {
      if (rows.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun dépôt à exporter')),
        );
      } else {
        if (action == 'csv') {
          await _exporter.exportCsv(
            rows: rows,
            title: 'FlyerTrack_Tournee',
          );
        } else {
          await _exporter.exportPdf(
            rows: rows,
            title: 'FlyerTrack_Tournee',
          );
        }
      }
    }

    // ✅ reset tournée quoi qu’il arrive
    await controller.endTour();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tournée terminée')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Riverpod: ouvrir la sheet quand pendingDepositId apparaît
    ref.listen(distributionControllerProvider, (prev, next) {
      final prevId = prev?.pendingDepositId;
      final nextId = next.pendingDepositId;

      if (nextId != null && nextId != prevId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBuildingConfirmSheet(next.pendingAddressLabel);
        });
      }
    });

    final state = ref.watch(distributionControllerProvider);
    final controller = ref.read(distributionControllerProvider.notifier);
    final db = ref.watch(appDbProvider);

    final isRunning = state.runState == DistributionRunState.running;

    // ✅ logique bouton fiable
    late final String buttonLabel;
    late final VoidCallback buttonAction;

    if (!state.hasStarted) {
      buttonLabel = 'Commencer';
      buttonAction = () => controller.startOrResume();
    } else if (isRunning) {
      buttonLabel = 'Pause';
      buttonAction = () => controller.pause();
    } else {
      buttonLabel = 'Reprendre';
      buttonAction = () => controller.startOrResume();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distribution'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Fin de tournée',
            onPressed: _endTour,
          ),
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Carte',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LiveMapPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Mini aperçu carte (apparaît après Commencer car current != null)
            if (state.current != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: LiveMapPreview(
                    center: state.current!,
                    route: state.route,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ✅ Stats "Apple minimal"
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRunning ? 'En distribution' : (state.hasStarted ? 'En pause' : 'Prêt'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Livrés: ${state.totalDelivered}',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    StreamBuilder<int>(
                      stream: db.watchNeedsReviewCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text('À vérifier: $count',
                            style: const TextStyle(fontSize: 16));
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dernière adresse: ${state.lastAddressLabel ?? "-"}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: buttonAction,
                child: Text(buttonLabel, style: const TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Mini carte non interactive (preview)
class LiveMapPreview extends StatelessWidget {
  final LatLng center;
  final List<LatLng> route;

  const LiveMapPreview({
    super.key,
    required this.center,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.flyertrack.app',
        ),
        if (route.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route,
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 22,
              height: 22,
              child: const Icon(Icons.circle, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}
