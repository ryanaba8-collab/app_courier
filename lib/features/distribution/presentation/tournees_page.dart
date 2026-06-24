import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import '../application/export_service.dart';

class TourneesPage extends ConsumerWidget {
  const TourneesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournées'),
      ),
      body: StreamBuilder<List<Tour>>(
        stream: db.watchAllTours(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tours = snapshot.data!;
          if (tours.isEmpty) {
            return const Center(child: Text('Aucune tournée.'));
          }

          return ListView.separated(
            itemCount: tours.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tour = tours[index];

              return _TourTile(
                tour: tour,
              );
            },
          );
        },
      ),
    );
  }
}

class _TourTile extends ConsumerWidget {
  final Tour tour;

  const _TourTile({
    required this.tour,
  });

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');

    return '$dd/$mm/$yyyy à $hh:$min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDbProvider);
    final exporter = ExportService();

    return FutureBuilder<List<int>>(
      future: Future.wait([
        db.countDeliveredByTour(tour.id),
        db.countReviewByTour(tour.id),
        db.countNoAdByTour(tour.id),
      ]),
      builder: (context, snapshot) {
        final delivered = snapshot.data?[0] ?? 0;
        final review = snapshot.data?[1] ?? 0;
        final noAd = snapshot.data?[2] ?? 0;

        return ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text('Tournée du ${_formatDate(tour.startedAt)}'),
          subtitle: Text(
            'Livrés: $delivered • À vérifier: $review • Pas de pub: $noAd',
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export_csv') {
                final rows = await db.getDepositsByTour(tour.id);
                await exporter.exportCsv(
                  rows: rows,
                  title: 'Tournee_${tour.id}',
                );
              }

              if (value == 'export_pdf') {
                final rows = await db.getDepositsByTour(tour.id);
                await exporter.exportPdf(
                  rows: rows,
                  title: 'Tournee_${tour.id}',
                );
              }

              if (value == 'delete') {
                if (!context.mounted) return;

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Supprimer la tournée ?'),
                    content: const Text(
                      'Cette action supprimera aussi tous les dépôts liés à cette tournée.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await db.deleteTourAndDeposits(tour.id);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tournée supprimée')),
                  );
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'export_csv',
                child: Text('Exporter CSV'),
              ),
              PopupMenuItem(
                value: 'export_pdf',
                child: Text('Exporter PDF'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer'),
              ),
            ],
          ),
        );
      },
    );
  }
}