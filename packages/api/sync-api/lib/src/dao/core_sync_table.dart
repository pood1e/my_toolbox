import 'package:drift/drift.dart';

import '../../sync_api.dart';

abstract class CoreSyncTable extends Table
    with LwwWithIdSyncTable, SoftDeleteSyncTable {
  // 这是一个空壳，目的是为了提供类型约束
  // 它保证了子类一定有 id, isDirty, updatedAt, deletedAt 等字段
}