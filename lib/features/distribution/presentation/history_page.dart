import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/export_service.dart';
import '../../../core/db/app_db.dart';
import '../../../core/db/db_provider.dart';
import 'group_detail_page.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  bool onlyReview = false;
  bool groupedView = true;

  final _exporter = ExportService();

  // Statut global d’un groupe:
  // - si au moins un "pas accès" => ❌
  // - sinon si au moins un "à vérifier" => ⚠️
  // - sinon => ✅
  int _aggregateStatus(List<Deposit> items) {
    if (items.any((d) => d.deliveryStatus == 1)) return 1;
    if (items.any((d) => d.deliveryStatus == 2)) return 2;
    return 0;
  }

  Future<void> _exportCsv() async {
    final db = ref.read(appDbProvider);
    final rows = onlyReview
        ? await db.watchNeedsReview().first
        : await db.watchAllDeposits().first;

    await _exporter.exportCsv(
      rows: rows,
      title: onlyReview ? 'a_verifier' : 'tous',
    );
  }

  Future<void> _exportPdf() async {
    final db = ref.read(appDbProvider);
    final rows = onlyReview
        ? await db.watchNeedsReview().first
        : await db.watchAllDeposits().first;

    await _exporter.exportPdf(
      rows: rows,
      title: onlyReview ? 'a_verifier' : 'tous',
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDbProvider);

    final Stream<List<Deposit>> stream =
        onlyReview ? db.watchNeedsReview() : db.watchAllDeposits();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            tooltip: 'Exporter CSV',
            icon: const Icon(Icons.table_view),
            onPressed: _exportCsv,
          ),
          IconButton(
            tooltip: 'Exporter PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Afficher seulement “À vérifier”'),
            value: onlyReview,
            onChanged: (v) => setState(() => onlyReview = v),
          ),
          SwitchListTile(
            title: const Text('Vue groupée (immeubles)'),
            value: groupedView,
            onChanged: (v) => setState(() => groupedView = v),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Deposit>>(
              stream: stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rows = snapshot.data!;
                if (rows.isEmpty) {
                  return const Center(child: Text('Aucun dépôt.'));
                }

                // ---------------- Vue simple ----------------
                if (!groupedView) {
                  return ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final d = rows[i];
                      final label = d.addressLabel ?? '(adresse inconnue)';

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
                        title: Text(label),
                        subtitle: Text(d.createdAt.toString()),
                        trailing: Text('${d.accuracy.toStringAsFixed(0)} m'),
                        onTap: () async {
                          await showModalBottomSheet(
                            context: context,
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
                                    const Text(
                                      'Corriger le dépôt',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(label),
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
                                        child: const Text(
                                          '❌ Accès impossible / Non livré',
                                        ),
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
                        },
                      );
                    },
                  );
                }

                // ---------------- Vue groupée ----------------
                final Map<int, List<Deposit>> groups = {};
                final List<Deposit> singles = [];

                for (final d in rows) {
                  final gid = d.groupId;
                  if (gid == null) {
                    singles.add(d);
                  } else {
                    groups.putIfAbsent(gid, () => []).add(d);
                  }
                }

                final groupEntries = groups.entries.toList()
                  ..sort((a, b) =>
                      b.value.first.createdAt.compareTo(a.value.first.createdAt));

                return ListView(
                  children: [
                    if (groupEntries.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Text(
                          'Immeubles',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...groupEntries.map((e) {
                        final gid = e.key;
                        final items = e.value;
                        final label =
                            items.first.addressLabel ?? '(adresse inconnue)';
                        final count = items.length;

                        final agg = _aggregateStatus(items);

                        final statusIcon = agg == 0
                            ? Icons.check_circle
                            : agg == 1
                                ? Icons.cancel
                                : Icons.warning;

                        final statusColor = agg == 0
                            ? Colors.green
                            : agg == 1
                                ? Colors.red
                                : Colors.orange;

                        return ListTile(
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.apartment),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Icon(
                                  statusIcon,
                                  size: 18,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          title: Text(label),
                          subtitle: Text('Boîtes: $count'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GroupDetailPage(
                                  groupId: gid,
                                  title: label,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                      const Divider(height: 1),
                    ],
                    if (singles.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Text(
                          'Maisons',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...singles.map((d) {
                        final label = d.addressLabel ?? '(adresse inconnue)';
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
                          title: Text(label),
                          subtitle: Text(d.createdAt.toString()),
                          trailing:
                              Text('${d.accuracy.toStringAsFixed(0)} m'),
                          onTap: () async {
                            await showModalBottomSheet(
                              context: context,
                              builder: (ctx) {
                                Future<void> setStatus(int s) async {
                                  Navigator.pop(ctx);
                                  await db.updateDepositStatusById(d.id, s);
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Corriger le dépôt',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(label),
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
                                          child: const Text(
                                            '❌ Accès impossible / Non livré',
                                          ),
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
                          },
                        );
                      }).toList(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
