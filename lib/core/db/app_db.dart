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

  // Nouvelle notion de tournée
  IntColumn get tourId => integer().nullable()();

  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracy => real()();

  TextColumn get addressLabel => text().nullable()();

  IntColumn get groupId => integer().nullable()();

  // 0=livré, 1=pas accès, 2=à vérifier
  IntColumn get deliveryStatus => integer().withDefault(const Constant(2))();

  BoolColumn get buildingSuspected =>
      boolean().withDefault(const Constant(false))();

  // Pas de pub
  BoolColumn get noAd => boolean().withDefault(const Constant(false))();
}

class DeliveryGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();

  TextColumn get addressId => text().nullable()();
  TextColumn get addressLabel => text().nullable()();

  RealColumn get centerLat => real()();
  RealColumn get centerLon => real()();
}

class Tours extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get name => text().nullable()();
}

@DriftDatabase(tables: [Deposits, DeliveryGroups, Tours])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
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

          if (from < 4) {
            await m.addColumn(deposits, col('no_ad'));
          }

          if (from < 5) {
            await m.createTable(tours);
            await m.addColumn(deposits, col('tour_id'));
          }
        },
      );

  // ---------- TOURS ----------

  Future<int> createTour({
    required DateTime startedAt,
    String? name,
  }) {
    return into(tours).insert(
      ToursCompanion.insert(
        startedAt: startedAt,
        name: Value(name),
      ),
    );
  }

  Future<void> closeTour(int tourId, DateTime endedAt) {
    return (update(tours)..where((t) => t.id.equals(tourId))).write(
      ToursCompanion(endedAt: Value(endedAt)),
    );
  }

  Future<List<Tour>> getAllTours() {
    return (select(tours)..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  Future<List<Deposit>> getDepositsByTour(int tourId) {
    return (select(deposits)
          ..where((t) => t.tourId.equals(tourId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Stream<List<Deposit>> watchDepositsByTour(int tourId) {
    return (select(deposits)
          ..where((t) => t.tourId.equals(tourId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<int> watchNeedsReviewCountByTour(int tourId) {
    final q = selectOnly(deposits)
      ..addColumns([deposits.id.count()])
      ..where(
        deposits.tourId.equals(tourId) & deposits.deliveryStatus.equals(2),
      );

    return q.watch().map((rows) {
      final row = rows.single;
      return row.read(deposits.id.count()) ?? 0;
    });
  }

  // ---------- INSERT / UPDATE ----------

  Future<int> insertDeposit({
    required DateTime createdAt,
    required double lat,
    required double lon,
    required double accuracy,
    String? addressLabel,
    int deliveryStatus = 2,
    bool buildingSuspected = false,
    int? groupId,
    int? tourId,
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
        tourId: Value(tourId),
      ),
    );
  }

  Future<void> updateDepositStatusById(int depositId, int newStatus) {
    return (update(deposits)..where((t) => t.id.equals(depositId))).write(
      DepositsCompanion(deliveryStatus: Value(newStatus)),
    );
  }

  Future<Deposit?> getLastDeposit({int? tourId}) {
    final q = select(deposits)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);

    if (tourId != null) {
      q.where((t) => t.tourId.equals(tourId));
    }

    return q.getSingleOrNull();
  }

  Future<void> setNoAdById(int depositId, bool value) {
    return (update(deposits)..where((t) => t.id.equals(depositId))).write(
      DepositsCompanion(noAd: Value(value)),
    );
  }

  Future<bool> hasNoAdForLabel(String label) async {
    final q = selectOnly(deposits)
      ..addColumns([deposits.id.count()])
      ..where(deposits.noAd.equals(true) & deposits.addressLabel.equals(label));

    final row = await q.getSingle();
    final count = row.read(deposits.id.count()) ?? 0;
    return count > 0;
  }

  // ---------- WATCH / QUERIES GLOBALES ----------

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

  // ---------- GROUPING ----------

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