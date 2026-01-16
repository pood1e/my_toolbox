import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../pomodoro_domain.dart';

// ==========================================
// 1. PomodoroSessions 表 (父表)
// ==========================================
@DataClassName('PomodoroSessionEntity')
class PomodoroSessions extends Table
    with
        IsDirtySyncTableMixin,
        CursorSyncTableMixin,
        UpdatedAtTableMixin,
        LwwTableMixin,
        DeletedAtTableMixin {
  // 使用 UUID 字符串作为主键
  TextColumn get id => text()();

  TextColumn get name => text()();

  // note 不能为空，但可以默认为空字符串
  TextColumn get note => text().nullable()();

  BoolColumn get manualClosed => boolean().withDefault(const Constant(false))();
  // 定义主键
  @override
  Set<Column> get primaryKey => {id};
}

// ==========================================
// 2. Pomodoros 表 (子表)
// ==========================================
@DataClassName('PomodoroEntity')
class Pomodoros extends Table
    with
        IsDirtySyncTableMixin,
        CursorSyncTableMixin,
        UpdatedAtTableMixin,
        LwwTableMixin,
        DeletedAtTableMixin {
  TextColumn get id => text()();

  // 外键关联：关联到 PomodoroSessions.id
  // onDelete: KeyAction.cascade 表示如果 Session 被删除了，对应的番茄钟记录也会自动删除
  TextColumn get sessionId =>
      text().references(PomodoroSessions, #id, onDelete: KeyAction.cascade)();

  IntColumn get startAt => integer()();

  IntColumn get endAt => integer()();

  // 存储枚举：Drift 会自动将枚举映射为 int (0, 1, 2)
  IntColumn get type => intEnum<PomodoroType>()();

  @override
  Set<Column> get primaryKey => {id};
}
