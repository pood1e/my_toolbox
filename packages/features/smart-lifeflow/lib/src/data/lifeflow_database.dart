import 'package:drift/drift.dart';

import 'tables/activity_log_table.dart';
import 'tables/activity_table.dart';
import 'tables/plan_table.dart';
import 'tables/schedule_item_table.dart';
import 'tables/task_definition_table.dart';
import 'tables/task_state_table.dart';
import '../domain/lifeflow_shared.dart';
import 'tables/converters.dart';

part 'lifeflow_database.g.dart';

@DriftDatabase(
  tables: [
    Activities,
    Plans,
    TaskDefinitions,
    TaskStates,
    ScheduleItems,
    ActivityLogs,
  ],
  daos: [],
)
class LifeflowDatabase extends _$LifeflowDatabase {
  // 构造函数：打开数据库连接
  LifeflowDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) async {
        // 1. 创建所有表
        await m.createAll();

        // 2. ✅【修正】在这里手动创建索引
        // 建议加上 IF NOT EXISTS 以防万一

        // --- Plans ---
        await customStatement('CREATE INDEX IF NOT EXISTS idx_plans_server_ver ON plans(server_updated_at)');

        // --- TaskDefinitions ---
        await customStatement('CREATE INDEX IF NOT EXISTS idx_task_defs_server_ver ON task_definitions(server_updated_at)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_task_defs_plan ON task_definitions(plan_id)');

        // --- TaskStates ---
        await customStatement('CREATE INDEX IF NOT EXISTS idx_task_states_server_ver ON task_states(server_updated_at)');

        // --- ScheduleItems ---
        await customStatement('CREATE INDEX IF NOT EXISTS idx_schedule_server_ver ON schedule_items(server_updated_at)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_schedule_day ON schedule_items(date, sort_order)');

        // --- TaskLogs ---
        await customStatement('CREATE INDEX IF NOT EXISTS idx_logs_server_ver ON task_logs(server_updated_at)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_logs_logical_date ON task_logs(logical_date)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_logs_task ON task_logs(task_id)');

        // --- Tags / Relations (如果有) ---
        // await customStatement('...');
      },

      // 如果你已经发布过版本，需要在 onUpgrade 里也加上这些索引的创建逻辑
      onUpgrade: (Migrator m, int from, int to) async {
        // if (from < 2) { ... create index ... }
      }
  );
}
