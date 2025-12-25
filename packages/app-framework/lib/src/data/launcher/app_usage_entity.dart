import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

@DataClassName('AppUsageEntity')
class AppUsageEntities extends Table with SyncTable {
  TextColumn get module => text().unique()();

  DateTimeColumn get lastUsedAt => dateTime()();

  IntColumn get openCount => integer().withDefault(const Constant(1))();
}
