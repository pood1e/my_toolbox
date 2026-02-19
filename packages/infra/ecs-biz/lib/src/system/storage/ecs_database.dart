// 假设的枚举定义（根据描述推断）
import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'tables/nodes.dart';
import '../config/data/property_configs.dart';
import '../sync/data/property_config_crdt.dart';
import '../relation/data/property_relations.dart';
import '../value/data/property_val.dart';
import '../value/value_service.dart';

part 'ecs_database.g.dart';

@DriftDatabase(
  tables: [
    Nodes,
    PropertyConfigs,
    PropertyConfigCrdts,
    PropertyRelations,
    PropertyVals,
  ],
  daos: [],
)
class EcsDatabase extends _$EcsDatabase {
  EcsDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // 开启外键约束 (SQLite 默认关闭)
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // 1. 首先让 Drift 创建所有表
      await m.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

@riverpod
Future<EcsDatabase> ecsDatabase(Ref ref) async => await ref.watch(
  userDbStoreProvider(const DatabaseId('ecs', EcsDatabase.new)).future,
);
