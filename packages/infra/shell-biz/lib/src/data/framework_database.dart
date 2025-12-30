import 'package:drift/drift.dart';

import 'launcher/app_usage_dao.dart';
import 'launcher/app_usage_entity.dart';
import 'sync/sync_sequence_table.dart';

part 'framework_database.g.dart';

@DriftDatabase(
  tables: [AppUsageEntities, SyncSequenceTable],
  daos: [AppUsageDao],
)
class FrameworkDatabase extends _$FrameworkDatabase {
  // 构造函数：打开数据库连接
  FrameworkDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
