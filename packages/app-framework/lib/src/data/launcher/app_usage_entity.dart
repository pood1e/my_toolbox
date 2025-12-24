import 'package:data_api/data_api.dart';
import 'package:sync_api/sync_api.dart';

@DataClassName('AppUsageEntity')
class AppUsageEntities extends Table with SyncTable {
  TextColumn get module => text().unique()();

  DateTimeColumn get lastUsedAt => dateTime()();

  IntColumn get openCount => integer().withDefault(const Constant(1))();
}
