import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/db_provider.dart';
import 'history_page.dart';
import '../application/distribution_controller.dart';

class DistributionPage extends ConsumerStatefulWidget {
  const DistributionPage({super.key});

  @override
  ConsumerState<DistributionPage> createState() => _DistributionPageState();
}

class _DistributionPageState extends ConsumerState<DistributionPage> {
  bool _sheetOpen = false;

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

  @override
  Widget build(BuildContext context) {
    // ✅ Riverpod: listen dans build
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

    // ✅ AJOUT: accès DB pour compter "À vérifier"
    final db = ref.watch(appDbProvider);

    final isRunning = state.runState == DistributionRunState.running;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distribution'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
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
            Text(
              'Livrés: ${state.totalDelivered}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),

            // ✅ NOUVEAU: compteur "À vérifier" en temps réel
            StreamBuilder<int>(
              stream: db.watchNeedsReviewCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Text(
                  'À vérifier: $count',
                  style: const TextStyle(fontSize: 18),
                );
              },
            ),

            const SizedBox(height: 8),
            Text(
              'Dernière adresse: ${state.lastAddressLabel ?? "-"}',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (isRunning) {
                    controller.pause();
                  } else {
                    controller.startOrResume();
                  }
                },
                child: Text(
                  isRunning ? 'Pause' : 'Reprendre',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
