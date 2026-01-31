// 假设的枚举定义（根据描述推断）
import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../domain/shared.dart';
import 'daos/field_dao.dart';
import 'daos/node_dao.dart';
import 'daos/trait_dao.dart';
import 'tables/field_refs.dart';
import 'tables/fields.dart';
import 'tables/nodes.dart';
import 'tables/role_refs.dart';
import 'tables/role_uses.dart';
import 'tables/roles.dart';
import 'tables/traits.dart';

part 'node_database.g.dart';

@DriftDatabase(
  tables: [Nodes, Roles, Traits, RoleUses, RoleRefs, Fields, FieldRefs],
  daos: [NodeDao, TraitDao, FieldDao],
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

      /// 确保非模板node的trait唯一
      await customStatement(
        'CREATE UNIQUE INDEX idx_traits_instance_unique ON traits(trait_type, node_id) WHERE role_id IS NULL',
      );
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
