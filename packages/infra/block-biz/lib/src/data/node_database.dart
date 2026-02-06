// 假设的枚举定义（根据描述推断）
import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../domain/stored_value.dart';
import 'daos/node_dao.dart';
import 'daos/property_atom_config_dao.dart';
import 'daos/property_dao.dart';
import 'tables/nodes.dart';
import 'tables/properties.dart';
import 'tables/property_config.dart';


part 'node_database.g.dart';

@DriftDatabase(
  tables: [Nodes, Properties, PropertyAtomConfigs],
  daos: [NodeDao, PropertyAtomConfigDao, PropertyDao],
)
class NodeDatabase extends _$NodeDatabase {
  NodeDatabase(super.e);

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
Future<NodeDatabase> nodeDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(DatabaseId('node', (e) => NodeDatabase(e))).future,
  );
}
