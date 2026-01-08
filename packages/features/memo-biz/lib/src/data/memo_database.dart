import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'memo_dao.dart';
import 'memo_table.dart';

part 'memo_database.g.dart';

@riverpod
Future<MemoDatabase> memoDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(DatabaseId('memo', (e) => MemoDatabase(e))).future,
  );
}

@DriftDatabase(tables: [Memos], daos: [MemoDao])
class MemoDatabase extends _$MemoDatabase {
  MemoDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // 1. 创建表结构
      await m.createAll();

      // 2. 创建性能与同步索引
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_memo_coc_dirty ON event(is_dirty)',
      );

      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_memo_coc_cursor ON event(server_updated_at)',
      );
    },
  );
}
