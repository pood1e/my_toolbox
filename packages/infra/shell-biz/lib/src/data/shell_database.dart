import 'package:drift/drift.dart';

import 'launcher/app_usage_dao.dart';
import 'launcher/app_usage_entity.dart';
import 'sync/sync_sequence_table.dart';

part 'shell_database.g.dart';

@DriftDatabase(
  tables: [AppUsageEntities, SyncSequenceTable],
  daos: [AppUsageDao],
)
class ShellDatabase extends _$ShellDatabase {
  // 构造函数：打开数据库连接
  ShellDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
