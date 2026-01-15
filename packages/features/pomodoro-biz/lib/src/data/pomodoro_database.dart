import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../pomodoro_domain.dart';
import 'pomodoro_dao.dart';
import 'pomodoro_tables.dart';

part 'pomodoro_database.g.dart';

@DriftDatabase(
  tables: [Pomodoros, PomodoroSessions],
  daos: [PomodoroDao, PomodoroSessionDao],
)
class PomodoroDatabase extends _$PomodoroDatabase
    with SyncTransactionalDbMixin {
  PomodoroDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // 1. 创建表结构
      await m.createAll();

      // 2. 创建性能与同步索引
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pomodoro_lww_dirty ON pomodoros(is_dirty)',
      );

      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pomodoro_lww_cursor ON pomodoros(server_updated_at)',
      );

      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pomodoro_session_lww_dirty ON pomodoro_sessions(is_dirty)',
      );

      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pomodoro_session_lww_cursor ON pomodoro_sessions(server_updated_at)',
      );
    },
  );
}

@riverpod
Future<PomodoroDatabase> pomodoroDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(
      DatabaseId('pomodoro', (e) => PomodoroDatabase(e)),
    ).future,
  );
}
