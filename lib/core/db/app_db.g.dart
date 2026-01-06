// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $DepositsTable extends Deposits with TableInfo<$DepositsTable, Deposit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DepositsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressLabelMeta = const VerificationMeta(
    'addressLabel',
  );
  @override
  late final GeneratedColumn<String> addressLabel = GeneratedColumn<String>(
    'address_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryStatusMeta = const VerificationMeta(
    'deliveryStatus',
  );
  @override
  late final GeneratedColumn<int> deliveryStatus = GeneratedColumn<int>(
    'delivery_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _buildingSuspectedMeta = const VerificationMeta(
    'buildingSuspected',
  );
  @override
  late final GeneratedColumn<bool> buildingSuspected = GeneratedColumn<bool>(
    'building_suspected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("building_suspected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    lat,
    lon,
    accuracy,
    addressLabel,
    groupId,
    deliveryStatus,
    buildingSuspected,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deposits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deposit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('address_label')) {
      context.handle(
        _addressLabelMeta,
        addressLabel.isAcceptableOrUnknown(
          data['address_label']!,
          _addressLabelMeta,
        ),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('delivery_status')) {
      context.handle(
        _deliveryStatusMeta,
        deliveryStatus.isAcceptableOrUnknown(
          data['delivery_status']!,
          _deliveryStatusMeta,
        ),
      );
    }
    if (data.containsKey('building_suspected')) {
      context.handle(
        _buildingSuspectedMeta,
        buildingSuspected.isAcceptableOrUnknown(
          data['building_suspected']!,
          _buildingSuspectedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deposit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deposit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      )!,
      addressLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_label'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      ),
      deliveryStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delivery_status'],
      )!,
      buildingSuspected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}building_suspected'],
      )!,
    );
  }

  @override
  $DepositsTable createAlias(String alias) {
    return $DepositsTable(attachedDatabase, alias);
  }
}

class Deposit extends DataClass implements Insertable<Deposit> {
  final int id;
  final DateTime createdAt;
  final double lat;
  final double lon;
  final double accuracy;
  final String? addressLabel;
  final int? groupId;
  final int deliveryStatus;
  final bool buildingSuspected;
  const Deposit({
    required this.id,
    required this.createdAt,
    required this.lat,
    required this.lon,
    required this.accuracy,
    this.addressLabel,
    this.groupId,
    required this.deliveryStatus,
    required this.buildingSuspected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['accuracy'] = Variable<double>(accuracy);
    if (!nullToAbsent || addressLabel != null) {
      map['address_label'] = Variable<String>(addressLabel);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<int>(groupId);
    }
    map['delivery_status'] = Variable<int>(deliveryStatus);
    map['building_suspected'] = Variable<bool>(buildingSuspected);
    return map;
  }

  DepositsCompanion toCompanion(bool nullToAbsent) {
    return DepositsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      lat: Value(lat),
      lon: Value(lon),
      accuracy: Value(accuracy),
      addressLabel: addressLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(addressLabel),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      deliveryStatus: Value(deliveryStatus),
      buildingSuspected: Value(buildingSuspected),
    );
  }

  factory Deposit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deposit(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      addressLabel: serializer.fromJson<String?>(json['addressLabel']),
      groupId: serializer.fromJson<int?>(json['groupId']),
      deliveryStatus: serializer.fromJson<int>(json['deliveryStatus']),
      buildingSuspected: serializer.fromJson<bool>(json['buildingSuspected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'accuracy': serializer.toJson<double>(accuracy),
      'addressLabel': serializer.toJson<String?>(addressLabel),
      'groupId': serializer.toJson<int?>(groupId),
      'deliveryStatus': serializer.toJson<int>(deliveryStatus),
      'buildingSuspected': serializer.toJson<bool>(buildingSuspected),
    };
  }

  Deposit copyWith({
    int? id,
    DateTime? createdAt,
    double? lat,
    double? lon,
    double? accuracy,
    Value<String?> addressLabel = const Value.absent(),
    Value<int?> groupId = const Value.absent(),
    int? deliveryStatus,
    bool? buildingSuspected,
  }) => Deposit(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    accuracy: accuracy ?? this.accuracy,
    addressLabel: addressLabel.present ? addressLabel.value : this.addressLabel,
    groupId: groupId.present ? groupId.value : this.groupId,
    deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    buildingSuspected: buildingSuspected ?? this.buildingSuspected,
  );
  Deposit copyWithCompanion(DepositsCompanion data) {
    return Deposit(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      addressLabel: data.addressLabel.present
          ? data.addressLabel.value
          : this.addressLabel,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      deliveryStatus: data.deliveryStatus.present
          ? data.deliveryStatus.value
          : this.deliveryStatus,
      buildingSuspected: data.buildingSuspected.present
          ? data.buildingSuspected.value
          : this.buildingSuspected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deposit(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracy: $accuracy, ')
          ..write('addressLabel: $addressLabel, ')
          ..write('groupId: $groupId, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('buildingSuspected: $buildingSuspected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    lat,
    lon,
    accuracy,
    addressLabel,
    groupId,
    deliveryStatus,
    buildingSuspected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deposit &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.accuracy == this.accuracy &&
          other.addressLabel == this.addressLabel &&
          other.groupId == this.groupId &&
          other.deliveryStatus == this.deliveryStatus &&
          other.buildingSuspected == this.buildingSuspected);
}

class DepositsCompanion extends UpdateCompanion<Deposit> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double> accuracy;
  final Value<String?> addressLabel;
  final Value<int?> groupId;
  final Value<int> deliveryStatus;
  final Value<bool> buildingSuspected;
  const DepositsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.addressLabel = const Value.absent(),
    this.groupId = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
    this.buildingSuspected = const Value.absent(),
  });
  DepositsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required double lat,
    required double lon,
    required double accuracy,
    this.addressLabel = const Value.absent(),
    this.groupId = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
    this.buildingSuspected = const Value.absent(),
  }) : createdAt = Value(createdAt),
       lat = Value(lat),
       lon = Value(lon),
       accuracy = Value(accuracy);
  static Insertable<Deposit> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? accuracy,
    Expression<String>? addressLabel,
    Expression<int>? groupId,
    Expression<int>? deliveryStatus,
    Expression<bool>? buildingSuspected,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (accuracy != null) 'accuracy': accuracy,
      if (addressLabel != null) 'address_label': addressLabel,
      if (groupId != null) 'group_id': groupId,
      if (deliveryStatus != null) 'delivery_status': deliveryStatus,
      if (buildingSuspected != null) 'building_suspected': buildingSuspected,
    });
  }

  DepositsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<double>? lat,
    Value<double>? lon,
    Value<double>? accuracy,
    Value<String?>? addressLabel,
    Value<int?>? groupId,
    Value<int>? deliveryStatus,
    Value<bool>? buildingSuspected,
  }) {
    return DepositsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      accuracy: accuracy ?? this.accuracy,
      addressLabel: addressLabel ?? this.addressLabel,
      groupId: groupId ?? this.groupId,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      buildingSuspected: buildingSuspected ?? this.buildingSuspected,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (addressLabel.present) {
      map['address_label'] = Variable<String>(addressLabel.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (deliveryStatus.present) {
      map['delivery_status'] = Variable<int>(deliveryStatus.value);
    }
    if (buildingSuspected.present) {
      map['building_suspected'] = Variable<bool>(buildingSuspected.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DepositsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracy: $accuracy, ')
          ..write('addressLabel: $addressLabel, ')
          ..write('groupId: $groupId, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('buildingSuspected: $buildingSuspected')
          ..write(')'))
        .toString();
  }
}

class $DeliveryGroupsTable extends DeliveryGroups
    with TableInfo<$DeliveryGroupsTable, DeliveryGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveryGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressIdMeta = const VerificationMeta(
    'addressId',
  );
  @override
  late final GeneratedColumn<String> addressId = GeneratedColumn<String>(
    'address_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressLabelMeta = const VerificationMeta(
    'addressLabel',
  );
  @override
  late final GeneratedColumn<String> addressLabel = GeneratedColumn<String>(
    'address_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _centerLatMeta = const VerificationMeta(
    'centerLat',
  );
  @override
  late final GeneratedColumn<double> centerLat = GeneratedColumn<double>(
    'center_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centerLonMeta = const VerificationMeta(
    'centerLon',
  );
  @override
  late final GeneratedColumn<double> centerLon = GeneratedColumn<double>(
    'center_lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    addressId,
    addressLabel,
    centerLat,
    centerLon,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeliveryGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('address_id')) {
      context.handle(
        _addressIdMeta,
        addressId.isAcceptableOrUnknown(data['address_id']!, _addressIdMeta),
      );
    }
    if (data.containsKey('address_label')) {
      context.handle(
        _addressLabelMeta,
        addressLabel.isAcceptableOrUnknown(
          data['address_label']!,
          _addressLabelMeta,
        ),
      );
    }
    if (data.containsKey('center_lat')) {
      context.handle(
        _centerLatMeta,
        centerLat.isAcceptableOrUnknown(data['center_lat']!, _centerLatMeta),
      );
    } else if (isInserting) {
      context.missing(_centerLatMeta);
    }
    if (data.containsKey('center_lon')) {
      context.handle(
        _centerLonMeta,
        centerLon.isAcceptableOrUnknown(data['center_lon']!, _centerLonMeta),
      );
    } else if (isInserting) {
      context.missing(_centerLonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliveryGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      addressId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_id'],
      ),
      addressLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_label'],
      ),
      centerLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}center_lat'],
      )!,
      centerLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}center_lon'],
      )!,
    );
  }

  @override
  $DeliveryGroupsTable createAlias(String alias) {
    return $DeliveryGroupsTable(attachedDatabase, alias);
  }
}

class DeliveryGroup extends DataClass implements Insertable<DeliveryGroup> {
  final int id;
  final DateTime createdAt;
  final String? addressId;
  final String? addressLabel;
  final double centerLat;
  final double centerLon;
  const DeliveryGroup({
    required this.id,
    required this.createdAt,
    this.addressId,
    this.addressLabel,
    required this.centerLat,
    required this.centerLon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || addressId != null) {
      map['address_id'] = Variable<String>(addressId);
    }
    if (!nullToAbsent || addressLabel != null) {
      map['address_label'] = Variable<String>(addressLabel);
    }
    map['center_lat'] = Variable<double>(centerLat);
    map['center_lon'] = Variable<double>(centerLon);
    return map;
  }

  DeliveryGroupsCompanion toCompanion(bool nullToAbsent) {
    return DeliveryGroupsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      addressId: addressId == null && nullToAbsent
          ? const Value.absent()
          : Value(addressId),
      addressLabel: addressLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(addressLabel),
      centerLat: Value(centerLat),
      centerLon: Value(centerLon),
    );
  }

  factory DeliveryGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryGroup(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      addressId: serializer.fromJson<String?>(json['addressId']),
      addressLabel: serializer.fromJson<String?>(json['addressLabel']),
      centerLat: serializer.fromJson<double>(json['centerLat']),
      centerLon: serializer.fromJson<double>(json['centerLon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'addressId': serializer.toJson<String?>(addressId),
      'addressLabel': serializer.toJson<String?>(addressLabel),
      'centerLat': serializer.toJson<double>(centerLat),
      'centerLon': serializer.toJson<double>(centerLon),
    };
  }

  DeliveryGroup copyWith({
    int? id,
    DateTime? createdAt,
    Value<String?> addressId = const Value.absent(),
    Value<String?> addressLabel = const Value.absent(),
    double? centerLat,
    double? centerLon,
  }) => DeliveryGroup(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    addressId: addressId.present ? addressId.value : this.addressId,
    addressLabel: addressLabel.present ? addressLabel.value : this.addressLabel,
    centerLat: centerLat ?? this.centerLat,
    centerLon: centerLon ?? this.centerLon,
  );
  DeliveryGroup copyWithCompanion(DeliveryGroupsCompanion data) {
    return DeliveryGroup(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      addressId: data.addressId.present ? data.addressId.value : this.addressId,
      addressLabel: data.addressLabel.present
          ? data.addressLabel.value
          : this.addressLabel,
      centerLat: data.centerLat.present ? data.centerLat.value : this.centerLat,
      centerLon: data.centerLon.present ? data.centerLon.value : this.centerLon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryGroup(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('addressId: $addressId, ')
          ..write('addressLabel: $addressLabel, ')
          ..write('centerLat: $centerLat, ')
          ..write('centerLon: $centerLon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, addressId, addressLabel, centerLat, centerLon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryGroup &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.addressId == this.addressId &&
          other.addressLabel == this.addressLabel &&
          other.centerLat == this.centerLat &&
          other.centerLon == this.centerLon);
}

class DeliveryGroupsCompanion extends UpdateCompanion<DeliveryGroup> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String?> addressId;
  final Value<String?> addressLabel;
  final Value<double> centerLat;
  final Value<double> centerLon;
  const DeliveryGroupsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.addressId = const Value.absent(),
    this.addressLabel = const Value.absent(),
    this.centerLat = const Value.absent(),
    this.centerLon = const Value.absent(),
  });
  DeliveryGroupsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    this.addressId = const Value.absent(),
    this.addressLabel = const Value.absent(),
    required double centerLat,
    required double centerLon,
  }) : createdAt = Value(createdAt),
       centerLat = Value(centerLat),
       centerLon = Value(centerLon);
  static Insertable<DeliveryGroup> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? addressId,
    Expression<String>? addressLabel,
    Expression<double>? centerLat,
    Expression<double>? centerLon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (addressId != null) 'address_id': addressId,
      if (addressLabel != null) 'address_label': addressLabel,
      if (centerLat != null) 'center_lat': centerLat,
      if (centerLon != null) 'center_lon': centerLon,
    });
  }

  DeliveryGroupsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<String?>? addressId,
    Value<String?>? addressLabel,
    Value<double>? centerLat,
    Value<double>? centerLon,
  }) {
    return DeliveryGroupsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      addressId: addressId ?? this.addressId,
      addressLabel: addressLabel ?? this.addressLabel,
      centerLat: centerLat ?? this.centerLat,
      centerLon: centerLon ?? this.centerLon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (addressId.present) {
      map['address_id'] = Variable<String>(addressId.value);
    }
    if (addressLabel.present) {
      map['address_label'] = Variable<String>(addressLabel.value);
    }
    if (centerLat.present) {
      map['center_lat'] = Variable<double>(centerLat.value);
    }
    if (centerLon.present) {
      map['center_lon'] = Variable<double>(centerLon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryGroupsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('addressId: $addressId, ')
          ..write('addressLabel: $addressLabel, ')
          ..write('centerLat: $centerLat, ')
          ..write('centerLon: $centerLon')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $DepositsTable deposits = $DepositsTable(this);
  late final $DeliveryGroupsTable deliveryGroups = $DeliveryGroupsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    deposits,
    deliveryGroups,
  ];
}

typedef $$DepositsTableCreateCompanionBuilder =
    DepositsCompanion Function({
      Value<int> id,
      required DateTime createdAt,
      required double lat,
      required double lon,
      required double accuracy,
      Value<String?> addressLabel,
      Value<int?> groupId,
      Value<int> deliveryStatus,
      Value<bool> buildingSuspected,
    });
typedef $$DepositsTableUpdateCompanionBuilder =
    DepositsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<double> lat,
      Value<double> lon,
      Value<double> accuracy,
      Value<String?> addressLabel,
      Value<int?> groupId,
      Value<int> deliveryStatus,
      Value<bool> buildingSuspected,
    });

class $$DepositsTableFilterComposer extends Composer<_$AppDb, $DepositsTable> {
  $$DepositsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressLabel => $composableBuilder(
    column: $table.addressLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get buildingSuspected => $composableBuilder(
    column: $table.buildingSuspected,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DepositsTableOrderingComposer
    extends Composer<_$AppDb, $DepositsTable> {
  $$DepositsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressLabel => $composableBuilder(
    column: $table.addressLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get buildingSuspected => $composableBuilder(
    column: $table.buildingSuspected,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DepositsTableAnnotationComposer
    extends Composer<_$AppDb, $DepositsTable> {
  $$DepositsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<String> get addressLabel => $composableBuilder(
    column: $table.addressLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get buildingSuspected => $composableBuilder(
    column: $table.buildingSuspected,
    builder: (column) => column,
  );
}

class $$DepositsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $DepositsTable,
          Deposit,
          $$DepositsTableFilterComposer,
          $$DepositsTableOrderingComposer,
          $$DepositsTableAnnotationComposer,
          $$DepositsTableCreateCompanionBuilder,
          $$DepositsTableUpdateCompanionBuilder,
          (Deposit, BaseReferences<_$AppDb, $DepositsTable, Deposit>),
          Deposit,
          PrefetchHooks Function()
        > {
  $$DepositsTableTableManager(_$AppDb db, $DepositsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DepositsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DepositsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DepositsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double> accuracy = const Value.absent(),
                Value<String?> addressLabel = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<int> deliveryStatus = const Value.absent(),
                Value<bool> buildingSuspected = const Value.absent(),
              }) => DepositsCompanion(
                id: id,
                createdAt: createdAt,
                lat: lat,
                lon: lon,
                accuracy: accuracy,
                addressLabel: addressLabel,
                groupId: groupId,
                deliveryStatus: deliveryStatus,
                buildingSuspected: buildingSuspected,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime createdAt,
                required double lat,
                required double lon,
                required double accuracy,
                Value<String?> addressLabel = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<int> deliveryStatus = const Value.absent(),
                Value<bool> buildingSuspected = const Value.absent(),
              }) => DepositsCompanion.insert(
                id: id,
                createdAt: createdAt,
                lat: lat,
                lon: lon,
                accuracy: accuracy,
                addressLabel: addressLabel,
                groupId: groupId,
                deliveryStatus: deliveryStatus,
                buildingSuspected: buildingSuspected,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DepositsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $DepositsTable,
      Deposit,
      $$DepositsTableFilterComposer,
      $$DepositsTableOrderingComposer,
      $$DepositsTableAnnotationComposer,
      $$DepositsTableCreateCompanionBuilder,
      $$DepositsTableUpdateCompanionBuilder,
      (Deposit, BaseReferences<_$AppDb, $DepositsTable, Deposit>),
      Deposit,
      PrefetchHooks Function()
    >;
typedef $$DeliveryGroupsTableCreateCompanionBuilder =
    DeliveryGroupsCompanion Function({
      Value<int> id,
      required DateTime createdAt,
      Value<String?> addressId,
      Value<String?> addressLabel,
      required double centerLat,
      required double centerLon,
    });
typedef $$DeliveryGroupsTableUpdateCompanionBuilder =
    DeliveryGroupsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String?> addressId,
      Value<String?> addressLabel,
      Value<double> centerLat,
      Value<double> centerLon,
    });

class $$DeliveryGroupsTableFilterComposer
    extends Composer<_$AppDb, $DeliveryGroupsTable> {
  $$DeliveryGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressId => $composableBuilder(
    column: $table.addressId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressLabel => $composableBuilder(
    column: $table.addressLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get centerLat => $composableBuilder(
    column: $table.centerLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get centerLon => $composableBuilder(
    column: $table.centerLon,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeliveryGroupsTableOrderingComposer
    extends Composer<_$AppDb, $DeliveryGroupsTable> {
  $$DeliveryGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressId => $composableBuilder(
    column: $table.addressId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressLabel => $composableBuilder(
    column: $table.addressLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get centerLat => $composableBuilder(
    column: $table.centerLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get centerLon => $composableBuilder(
    column: $table.centerLon,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeliveryGroupsTableAnnotationComposer
    extends Composer<_$AppDb, $DeliveryGroupsTable> {
  $$DeliveryGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get addressId =>
      $composableBuilder(column: $table.addressId, builder: (column) => column);

  GeneratedColumn<String> get addressLabel => $composableBuilder(
    column: $table.addressLabel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get centerLat =>
      $composableBuilder(column: $table.centerLat, builder: (column) => column);

  GeneratedColumn<double> get centerLon =>
      $composableBuilder(column: $table.centerLon, builder: (column) => column);
}

class $$DeliveryGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $DeliveryGroupsTable,
          DeliveryGroup,
          $$DeliveryGroupsTableFilterComposer,
          $$DeliveryGroupsTableOrderingComposer,
          $$DeliveryGroupsTableAnnotationComposer,
          $$DeliveryGroupsTableCreateCompanionBuilder,
          $$DeliveryGroupsTableUpdateCompanionBuilder,
          (
            DeliveryGroup,
            BaseReferences<_$AppDb, $DeliveryGroupsTable, DeliveryGroup>,
          ),
          DeliveryGroup,
          PrefetchHooks Function()
        > {
  $$DeliveryGroupsTableTableManager(_$AppDb db, $DeliveryGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeliveryGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeliveryGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeliveryGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> addressId = const Value.absent(),
                Value<String?> addressLabel = const Value.absent(),
                Value<double> centerLat = const Value.absent(),
                Value<double> centerLon = const Value.absent(),
              }) => DeliveryGroupsCompanion(
                id: id,
                createdAt: createdAt,
                addressId: addressId,
                addressLabel: addressLabel,
                centerLat: centerLat,
                centerLon: centerLon,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime createdAt,
                Value<String?> addressId = const Value.absent(),
                Value<String?> addressLabel = const Value.absent(),
                required double centerLat,
                required double centerLon,
              }) => DeliveryGroupsCompanion.insert(
                id: id,
                createdAt: createdAt,
                addressId: addressId,
                addressLabel: addressLabel,
                centerLat: centerLat,
                centerLon: centerLon,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeliveryGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $DeliveryGroupsTable,
      DeliveryGroup,
      $$DeliveryGroupsTableFilterComposer,
      $$DeliveryGroupsTableOrderingComposer,
      $$DeliveryGroupsTableAnnotationComposer,
      $$DeliveryGroupsTableCreateCompanionBuilder,
      $$DeliveryGroupsTableUpdateCompanionBuilder,
      (
        DeliveryGroup,
        BaseReferences<_$AppDb, $DeliveryGroupsTable, DeliveryGroup>,
      ),
      DeliveryGroup,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$DepositsTableTableManager get deposits =>
      $$DepositsTableTableManager(_db, _db.deposits);
  $$DeliveryGroupsTableTableManager get deliveryGroups =>
      $$DeliveryGroupsTableTableManager(_db, _db.deliveryGroups);
}
