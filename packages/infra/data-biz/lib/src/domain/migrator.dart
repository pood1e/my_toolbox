import 'package:drift/drift.dart';

import '../scope/data_scope.dart';
import 'kv_store.dart';

typedef MigrationDbFactory = GeneratedDatabase Function(DataScope scope);

/// [业务迁移协议]
/// 每个业务模块实现此接口，定义如何从 Guest 搬运数据到 User
abstract class FeatureDbMigrator {
  /// 执行迁移
  /// [guestDb]: 源数据库 (只读)
  /// [userDb]: 目标数据库 (读写)
  Future<void> migrate(GeneratedDatabase guestDb, GeneratedDatabase userDb);
}

/// [业务 KV 迁移协议]
abstract class FeatureKvMigrator {
  /// 1. 告诉框架，你要迁移哪个 KV 实例
  /// 例如: 'settings', 'im_cache'
  String get kvStoreName;

  /// 2. 执行迁移逻辑
  /// [guestKv]: 源 KV (只读)
  /// [userKv]: 目标 KV (读写)
  Future<void> migrate(KVStore guestKv, KVStore userKv);
}
