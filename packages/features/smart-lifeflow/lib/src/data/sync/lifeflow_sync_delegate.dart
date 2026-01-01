import 'package:app_core/http.dart';
import 'package:app_core/object.dart';
import 'package:framework_api/framework_api.dart';

import '../../data/daos/activity_dao.dart';
import '../../data/daos/activity_log_dao.dart';
import '../../data/daos/daily_snapshot_dao.dart';
import '../../data/daos/plan_dao.dart';
import '../../data/daos/schedule_item_dao.dart';
import '../../data/daos/task_definition_dao.dart';
import '../../data/daos/task_state_dao.dart';
import '../dtos/sync_dtos.dart';
import '../lifeflow_database.dart';
import '../mapper/sync_mappers.dart';

class LifeflowSyncDelegate implements SyncDelegate {
  final LifeflowDatabase _db;
  final Dio _dio;

  // 各个表的 DAO
  final ActivityDao _activityDao;
  final PlanDao _planDao;
  final TaskDefinitionDao _taskDefDao;
  final TaskStateDao _taskStateDao;
  final ScheduleItemDao _scheduleDao;
  final ActivityLogDao _logDao;
  final DailySnapshotDao _snapshotDao;

  LifeflowSyncDelegate({
    required LifeflowDatabase db,
    required Dio dio,
    required ActivityDao activityDao,
    required PlanDao planDao,
    required TaskDefinitionDao taskDefDao,
    required TaskStateDao taskStateDao,
    required ScheduleItemDao scheduleDao,
    required ActivityLogDao logDao,
    required DailySnapshotDao snapshotDao,
  }) : _db = db,
       _dio = dio,
       _activityDao = activityDao,
       _planDao = planDao,
       _taskDefDao = taskDefDao,
       _taskStateDao = taskStateDao,
       _scheduleDao = scheduleDao,
       _logDao = logDao,
       _snapshotDao = snapshotDao;

  @override
  String get resourceId => 'lifeflow';

  @override
  Future<void> sync() async {
    // =================================================================
    // 步骤 1: 准备阶段 (Prepare & Snapshot)
    // =================================================================

    // 1.1 获取本地脏数据
    final dirtyActs = await _activityDao.getDirtyItems();
    final dirtyPlans = await _planDao.getDirtyItems();
    final dirtyDefs = await _taskDefDao.getDirtyItems();
    final dirtyStates = await _taskStateDao.getDirtyItems();
    final dirtySchedules = await _scheduleDao.getDirtyItems();
    final dirtyLogs = await _logDao.getDirtyItems();
    final dirtySnaps = await _snapshotDao.getDirtyItems();

    // 1.2 【关键】构建快照 (ID -> LocalUpdatedAt)
    // 我们必须记录发送瞬间的本地时间戳。
    // 如果在网络请求期间用户修改了数据，本地时间戳会更新。
    // 处理 Ack 时，如果发现本地时间戳 != 快照时间戳，则不清除脏标记。
    final actSnapshot = {for (var i in dirtyActs) i.id: i.updatedAt};
    final planSnapshot = {for (var i in dirtyPlans) i.id: i.updatedAt};
    final defSnapshot = {for (var i in dirtyDefs) i.id: i.updatedAt};
    final stateSnapshot = {
      for (var i in dirtyStates) i.taskId: i.updatedAt,
    }; // 注意 State 主键是 taskId
    final scheduleSnapshot = {for (var i in dirtySchedules) i.id: i.updatedAt};
    final logSnapshot = {for (var i in dirtyLogs) i.id: i.updatedAt};
    final snapSnapshot = {for (var i in dirtySnaps) i.id: i.updatedAt};

    // 1.3 收集游标
    final cursors = {
      'activities': await _activityDao.getMaxCursor(),
      'plans': await _planDao.getMaxCursor(),
      'task_definitions': await _taskDefDao.getMaxCursor(),
      'task_states': await _taskStateDao.getMaxCursor(),
      'schedule_items': await _scheduleDao.getMaxCursor(),
      'activity_logs': await _logDao.getMaxCursor(),
      'daily_snapshots': await _snapshotDao.getMaxCursor(),
    };

    // 1.4 构建请求 Payload
    final pushPayload = SyncPayload(
      activities: dirtyActs.map((e) => e.toDto()).toList(),
      plans: dirtyPlans.map((e) => e.toDto()).toList(),
      taskDefinitions: dirtyDefs.map((e) => e.toDto()).toList(),
      taskStates: dirtyStates.map((e) => e.toDto()).toList(),
      scheduleItems: dirtySchedules.map((e) => e.toDto()).toList(),
      activityLogs: dirtyLogs.map((e) => e.toDto()).toList(),
      dailySnapshots: dirtySnaps.map((e) => e.toDto()).toList(),
    );

    // =================================================================
    // 步骤 2: 网络交互 (Network)
    // =================================================================

    final request = SyncRequest(cursors: cursors, push: pushPayload);
    final dioResponse = await _dio.post('/lifeflow/sync', data: request);
    final response = R
        .fromJson(
          dioResponse.data,
          (t) => SyncResponse.fromJson(t as Map<String, dynamic>),
        )
        .data!;

    // =================================================================
    // 步骤 3: 事务回写 (Transaction Commit)
    // =================================================================

    await _db.transaction(() async {
      // --- 3.1 处理 Ack (乐观清理) ---
      // 将服务端确认的 ID 标记为 Clean，并更新 ServerUpdatedAt
      // 传入 snapshot 进行防并发检查
      final acks = response.ackedIds;
      if (acks != null) {
        if (acks['activities'] != null) {
          await _activityDao.markSynced(acks['activities']!, actSnapshot);
        }
        if (acks['plans'] != null) {
          await _planDao.markSynced(acks['plans']!, planSnapshot);
        }
        if (acks['task_definitions'] != null) {
          await _taskDefDao.markSynced(acks['task_definitions']!, defSnapshot);
        }
        if (acks['task_states'] != null) {
          await _taskStateDao.markSynced(acks['task_states']!, stateSnapshot);
        }
        if (acks['schedule_items'] != null) {
          await _scheduleDao.markSynced(
            acks['schedule_items']!,
            scheduleSnapshot,
          );
        }
        if (acks['activity_logs'] != null) {
          await _logDao.markSynced(acks['activity_logs']!, logSnapshot);
        }
        if (acks['daily_snapshots'] != null) {
          await _snapshotDao.markSynced(acks['daily_snapshots']!, snapSnapshot);
        }
      }

      // --- 3.2 处理 Changes (应用远程变更) ---
      // 写入顺序：Parent -> Child 以满足外键约束
      final changes = response.changes;
      if (changes != null) {
        if (changes.activities.isNotEmpty) {
          await _activityDao.applyRemote(changes.activities);
        }
        if (changes.plans.isNotEmpty) await _planDao.applyRemote(changes.plans);

        // Task 体系
        if (changes.taskDefinitions.isNotEmpty) {
          await _taskDefDao.applyRemote(changes.taskDefinitions);
        }
        if (changes.taskStates.isNotEmpty) {
          await _taskStateDao.applyRemote(changes.taskStates);
        }

        // 日程与日志
        if (changes.scheduleItems.isNotEmpty) {
          await _scheduleDao.applyRemote(changes.scheduleItems);
        }
        if (changes.activityLogs.isNotEmpty) {
          await _logDao.applyRemote(changes.activityLogs);
        }

        // 其他
        if (changes.dailySnapshots.isNotEmpty) {
          await _snapshotDao.applyRemote(changes.dailySnapshots);
        }
      }
    });
  }
}
