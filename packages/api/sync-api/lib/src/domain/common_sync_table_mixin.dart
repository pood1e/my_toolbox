import 'package:drift/drift.dart';

/// 服务器更新游标
/// 添加索引加快cursor获取
/// CREATE INDEX IF NOT EXISTS idx_xx_sync ON xx(server_updated_at)
mixin CursorSyncTableMixin on Table {
  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();
}

/// 脏标记
mixin IsDirtySyncTableMixin on Table {
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
}
