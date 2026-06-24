import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../application/distribution_controller.dart';

class LiveMapPage extends ConsumerWidget {
  const LiveMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(distributionControllerProvider);
    final db = ref.watch(appDbProvider);

    final cur = state.current ?? const LatLng(48.8566, 2.3522);
    final tourId = state.currentTourId;

    final Stream<List<Deposit>> depositsStream =
        tourId == null ? Stream.value(<Deposit>[]) : db.watchDepositsByTour(tourId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte (Live)'),
      ),
      body: StreamBuilder<List<Deposit>>(
        stream: depositsStream,
        builder: (context, snapshot) {
          final deposits = snapshot.data ?? const <Deposit>[];

          final markers = <Marker>[];

          for (final d in deposits) {
            final pos = LatLng(d.lat, d.lon);

            final icon = d.noAd
                ? Icons.block
                : d.deliveryStatus == 0
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

          markers.add(
            Marker(
              point: cur,
              width: 44,
              height: 44,
              child: const Icon(Icons.my_location),
            ),
          );

          final track = state.route;

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
              if (track.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: track, strokeWidth: 4),
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