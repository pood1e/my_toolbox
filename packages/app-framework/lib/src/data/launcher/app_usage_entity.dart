import 'package:drift/drift.dart';

@DataClassName('AppUsage')
class AppUsageEntities extends Table {
  TextColumn get module => text()();

  IntColumn get lastUsedAt => integer()();

  IntColumn get openCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {module};

  // sync part
  IntColumn get unsyncCount => integer().withDefault(const Constant(0))();

  IntColumn get lockedCount => integer().withDefault(const Constant(0))();
}
