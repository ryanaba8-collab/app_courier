// lib/core/db/app_db.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_db.g.dart';

class Deposits extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();

  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracy => real()();

  // BAN label (ex: "10 Rue ... 750.. Paris")
  TextColumn get addressLabel => text().nullable()();

  // Grouping (nullable)
  IntColumn get groupId => integer().nullable()();

  // 0=livré, 1=pas accès, 2=à vérifier (par défaut)
  IntColumn get deliveryStatus => integer().withDefault(const Constant(2))();

  // "immeuble probable"
  BoolColumn get buildingSuspected =>
      boolean().withDefault(const Constant(false))();
}

class DeliveryGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();

  TextColumn get addressId => text().nullable()(); // BAN id (optionnel)
  TextColumn get addressLabel => text().nullable()();

  RealColumn get centerLat => real()();
  RealColumn get centerLon => real()();
}

@DriftDatabase(tables: [Deposits, DeliveryGroups])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Drift veut une GeneratedColumn<Object> pour addColumn
          GeneratedColumn<Object> col(String name) =>
              deposits.$columns.singleWhere((c) => c.$name == name);

          if (from < 2) {
            await m.createTable(deliveryGroups);
            await m.addColumn(deposits, col('group_id'));
          }

          if (from < 3) {
            await m.addColumn(deposits, col('delivery_status'));
            await m.addColumn(deposits, col('building_suspected'));
          }
        },
      );

  // ---------- INSERT / UPDATE ----------

  Future<int> insertDeposit({
    required DateTime createdAt,
    required double lat,
    required double lon,
    required double accuracy,
    String? addressLabel,
    int deliveryStatus = 2, // default: À vérifier
    bool buildingSuspected = false,
    int? groupId,
  }) {
    return into(deposits).insert(
      DepositsCompanion.insert(
        createdAt: createdAt,
        lat: lat,
        lon: lon,
        accuracy: accuracy,
        addressLabel: Value(addressLabel),
        deliveryStatus: Value(deliveryStatus),
        buildingSuspected: Value(buildingSuspected),
        groupId: Value(groupId),
      ),
    );
  }

  Future<void> updateDepositStatusById(int depositId, int newStatus) {
    return (update(deposits)..where((t) => t.id.equals(depositId))).write(
      DepositsCompanion(deliveryStatus: Value(newStatus)),
    );
  }

  // ---------- WATCH / QUERIES ----------

  Stream<int> watchCount() {
    return select(deposits).watch().map((rows) => rows.length);
  }

  Stream<List<Deposit>> watchAllDeposits() {
    return (select(deposits)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<Deposit>> watchNeedsReview() {
    return (select(deposits)
          ..where((t) => t.deliveryStatus.equals(2))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<int> watchNeedsReviewCount() {
    final q = selectOnly(deposits)
      ..addColumns([deposits.id.count()])
      ..where(deposits.deliveryStatus.equals(2));

    return q.watch().map((rows) {
      final row = rows.single;
      return row.read(deposits.id.count()) ?? 0;
    });
    
  }
Stream<List<Deposit>> watchDepositsByGroup(int groupId) {
  return (select(deposits)
        ..where((t) => t.groupId.equals(groupId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
}

Future<void> updateGroupStatus(int groupId, int newStatus) {
  return (update(deposits)..where((t) => t.groupId.equals(groupId))).write(
    DepositsCompanion(deliveryStatus: Value(newStatus)),
  );
}

  // ---------- GROUPING (immeubles) ----------

  Future<List<DeliveryGroup>> getRecentGroups(DateTime since) {
    return (select(deliveryGroups)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(30))
        .get();
  }

  Future<int> createDeliveryGroup({
    required DateTime createdAt,
    required double centerLat,
    required double centerLon,
    String? addressId,
    String? addressLabel,
  }) {
    return into(deliveryGroups).insert(
      DeliveryGroupsCompanion.insert(
        createdAt: createdAt,
        centerLat: centerLat,
        centerLon: centerLon,
        addressId: Value(addressId),
        addressLabel: Value(addressLabel),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
