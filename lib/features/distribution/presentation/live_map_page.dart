import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/db/db_provider.dart';
import '../application/distribution_controller.dart';

class LiveMapPage extends ConsumerWidget {
  const LiveMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(distributionControllerProvider);
    final db = ref.watch(appDbProvider);

    // Position actuelle (fallback: Paris)
    final cur = state.current ?? const LatLng(48.8566, 2.3522);

    return Scaffold(
      appBar: AppBar(title: const Text('Carte (Live)')),
      body: StreamBuilder(
        stream: db.watchAllDeposits(),
        builder: (context, snapshot) {
          final deposits = snapshot.data ?? const [];

          final markers = <Marker>[];

          // Dépôts (markers)
          for (final d in deposits) {
            final pos = LatLng(d.lat, d.lon);

            final icon = d.deliveryStatus == 0
                ? Icons.check_circle
                : d.deliveryStatus == 1
                    ? Icons.cancel
                    : Icons.warning;

            markers.add(
              Marker(
                point: pos,
                width: 40,
                height: 40,
                child: Icon(icon),
              ),
            );
          }

          // Position actuelle (marker)
          markers.add(
            Marker(
              point: cur,
              width: 44,
              height: 44,
              child: const Icon(Icons.my_location),
            ),
          );

          final route = state.route;
          final fullTrack = state.fullTrack;

          return FlutterMap(
            options: MapOptions(
              initialCenter: cur,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.appcourier.app',
              ),

              // Route ORS
              // ✅ Tracé complet (tournée réelle)
if (fullTrack.isNotEmpty)
  PolylineLayer(
    polylines: [
      Polyline(points: fullTrack, strokeWidth: 4),
    ],
  ),

// ✅ Route ORS (itinéraire vers la prochaine cible)
if (route.isNotEmpty)
  PolylineLayer(
    polylines: [
      Polyline(points: route, strokeWidth: 6),
    ],
  ),


              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
