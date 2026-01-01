import 'package:drift/drift.dart';

@DataClassName('DailySnapshotEntity')
class DailySnapshots extends Table {
  TextColumn get id => text()(); // date string "2023-10-27"
  IntColumn get date => integer()();

  IntColumn get energyStart => integer().nullable()();

  IntColumn get energyEnd => integer().nullable()();

  TextColumn get review => text().nullable()();

  // Sync (如果需要多端同步复盘记录)
  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();

  IntColumn get deletedAt => integer().nullable()();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
