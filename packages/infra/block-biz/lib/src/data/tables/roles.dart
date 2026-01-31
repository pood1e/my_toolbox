import 'package:drift/drift.dart';

import 'nodes.dart';

@DataClassName('RoleEntity')
@TableIndex(
  name: 'idx_roles_node',
  columns: {#nodeId},
) // 加速查询挂载在特定Node上的自定义Role
class Roles extends Table {
  TextColumn get id => text()();

  TextColumn get nodeId =>
      text().nullable().references(Nodes, #id, onDelete: KeyAction.cascade)();

  BoolColumn get appendIfSuit => boolean().withDefault(const Constant(false))();

  // Local fields
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
