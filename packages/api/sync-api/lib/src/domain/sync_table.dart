import 'package:data_api/data_api.dart';
import 'package:drift/drift.dart';


/// 添加索引加快cursor获取
/// CREATE INDEX IF NOT EXISTS idx_xx_sync ON xx(server_updated_at)
abstract class SyncTable extends Table {
  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();
}

abstract class SyncEntity implements IdObject {
  int get serverUpdatedAt;
}