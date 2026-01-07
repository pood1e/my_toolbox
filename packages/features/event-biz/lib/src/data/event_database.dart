import 'package:drift/drift.dart';

import 'event_dao.dart';
import 'event_table.dart';

part 'event_database.g.dart';

@DriftDatabase(tables: [Events], daos: [EventDao])
class EventDatabase extends _$EventDatabase {
  EventDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // 1. 创建表结构
      await m.createAll();

      // 2. 创建性能与同步索引
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_event_lww_dirty ON event(is_dirty)',
      );

      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_event_lww_cursor ON event(server_updated_at)',
      );
    },
  );
}
