import 'package:drift/drift.dart';

import 'daos/activity_dao.dart';
import 'daos/activity_log_dao.dart';
import 'daos/daily_snapshot_dao.dart';
import 'daos/plan_dao.dart';
import 'daos/schedule_item_dao.dart';
import 'daos/task_definition_dao.dart';
import 'daos/task_state_dao.dart';
import 'tables/activity_log_table.dart';
import 'tables/activity_table.dart';
import 'tables/daily_snapshot_table.dart';
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
    DailySnapshots,
  ],
  daos: [
    ActivityDao,
    ActivityLogDao,
    DailySnapshotDao,
    PlanDao,
    ScheduleItemDao,
    TaskDefinitionDao,
    TaskStateDao,
  ],
)
class LifeflowDatabase extends _$LifeflowDatabase {
  // 构造函数：打开数据库连接
  LifeflowDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_activities_sync ON activities(server_updated_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_plans_sync ON plans(server_updated_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_task_defs_sync ON task_definitions(server_updated_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_task_defs_plan ON task_definitions(plan_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_task_states_sync ON task_states(server_updated_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_schedule_sync ON schedule_items(server_updated_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_schedule_day ON schedule_items(date, sort_order)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_logs_sync ON activity_logs(server_updated_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_logs_logical_date ON activity_logs(logical_date)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_snapshots_sync ON daily_snapshots(server_updated_at)',
      );
    },
  );
}
