import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';

class GroupDetailPage extends ConsumerWidget {
  final int groupId;
  final String title;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.title,
  });

  Future<void> _showFixOneDepositSheet(AppDb db, Deposit d, BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (ctx) {
        Future<void> setStatus(int s) async {
          Navigator.pop(ctx);
          await db.updateDepositStatusById(d.id, s);
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Corriger une boîte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(d.addressLabel ?? '(adresse inconnue)'),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setStatus(0),
                  child: const Text('✅ Livré'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => setStatus(1),
                  child: const Text('❌ Accès impossible / Non livré'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => setStatus(2),
                  child: const Text('⚠️ À vérifier'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFixWholeGroupSheet(AppDb db, BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (ctx) {
        Future<void> setGroup(int s) async {
          Navigator.pop(ctx);
          await db.updateGroupStatus(groupId, s);
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Corriger TOUT l’immeuble', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(title),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setGroup(0),
                  child: const Text('✅ Tout livré'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => setGroup(1),
                  child: const Text('❌ Accès impossible (tout non livré)'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => setGroup(2),
                  child: const Text('⚠️ Tout à vérifier'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showFixWholeGroupSheet(db, context),
            tooltip: 'Corriger tout l’immeuble',
          ),
        ],
      ),
      body: StreamBuilder<List<Deposit>>(
        stream: db.watchDepositsByGroup(groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('Aucune boîte dans cet immeuble.'));
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = rows[i];
              final status = d.deliveryStatus;

              final icon = status == 0
                  ? Icons.check_circle
                  : status == 1
                      ? Icons.cancel
                      : Icons.warning;

              final iconColor = status == 0
                  ? Colors.green
                  : status == 1
                      ? Colors.red
                      : Colors.orange;

              return ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text('Boîte #${rows.length - i}'),
                subtitle: Text(d.createdAt.toString()),
                trailing: Text('${d.accuracy.toStringAsFixed(0)} m'),
                onTap: () => _showFixOneDepositSheet(db, d, context),
              );
            },
          );
        },
      ),
    );
  }
}
