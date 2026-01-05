import 'package:drift/drift.dart';

import '../domain/sync_table.dart';
import 'lww_models.dart';

/// 添加索引加快cursor获取
/// CREATE INDEX IF NOT EXISTS idx_xx_lww ON xx(isDirty,server_updated_at)
abstract class LwwTable extends SyncTable {
  IntColumn get updatedAt => integer()();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
}

abstract class LwwEntity implements LwwObject {
  bool get isDirty;
}
