import 'package:drift/drift.dart';

import 'daos/reality_daos.dart';
import 'tables/reality_tables.dart';

part 'lifeflow_database.g.dart';

@DriftDatabase(
  tables: [
    // 1. Reality (现实相)
    Activities,
    ActivityLogs,
    ActivityShortcuts,
  ],
  daos: [ActivityDao, ActivityLogDao, ActivityShortcutDao],
)
class LifeflowDatabase extends _$LifeflowDatabase {
  LifeflowDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // 1. 创建表结构
      await m.createAll();

      // 2. 创建性能与同步索引
      await _createIndices(m);

      // 3. 填充系统预置数据
      await batch((b) => _populatePresets(b));
    },
    beforeOpen: (details) async {
      // 开启外键支持 (关键：用于级联删除)
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// 创建索引
  Future<void> _createIndices(Migrator m) async {
    // --- A. 同步索引 (Sync Performance) ---
    // 联合索引 is_dirty + server_updated_at 用于加速 SyncDelegate 的查询

    // Activities
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_activities_sync ON activities(is_dirty, server_updated_at)',
    );

    // ActivityLogs
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_logs_sync ON activity_logs(is_dirty, server_updated_at)',
    );

    // ActivityShortcuts
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shortcuts_sync ON activity_shortcuts(is_dirty, server_updated_at)',
    );

    // --- B. 业务查询索引 (Query Performance) ---

    // 1. Logs: 时间轴查询 (最高频)
    // UI: "展示今天的流水" -> WHERE start_time BETWEEN ? AND ?
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_logs_time ON activity_logs(start_time)',
    );

    // 2. Logs: 统计查询
    // UI: "这个活动做了多少次" -> WHERE activity_id = ?
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_logs_activity ON activity_logs(activity_id)',
    );

    // 3. Shortcuts: 排序
    // UI: "快捷方式列表" -> ORDER BY sort_order
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shortcuts_sort ON activity_shortcuts(sort_order)',
    );
  }

  /// 填充预置数据
  Future<void> _populatePresets(Batch batch) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // 预置常用活动
    // 使用固定 ID (preset_*)，方便后续逻辑判断或防止重复
    final presets = [
      _buildPreset('work', '工作', '💼', 'F44336', now), // Red
      _buildPreset('study', '学习', '📚', '2196F3', now), // Blue
      _buildPreset('sleep', '睡眠', '🛌', '3F51B5', now), // Indigo
      _buildPreset('sport', '运动', '🏃', '4CAF50', now), // Green
      _buildPreset('life', '生活', '🏠', '795548', now), // Brown
      _buildPreset('fun', '娱乐', '🎮', 'E91E63', now), // Pink
      _buildPreset('commute', '通勤', '🚗', '607D8B', now), // BlueGrey
    ];

    batch.insertAll(activities, presets);
  }

  // 辅助构建函数
  ActivitiesCompanion _buildPreset(
    String key,
    String name,
    String icon,
    String color,
    int now,
  ) {
    return ActivitiesCompanion.insert(
      id: 'preset_$key',
      name: name,
      icon: Value(icon),
      colorHex: Value(color),
      // Sync Meta
      createdAt: now,
      updatedAt: now,
      serverUpdatedAt: const Value(0),
      isDirty: const Value(true), // 初始数据也标记为脏，以便同步到云端
    );
  }
}
