import 'package:drift/drift.dart';

import 'nodes.dart';
import 'roles.dart';

@DataClassName('RoleUseEntity')
@TableIndex(
  name: 'idx_role_use_role',
  columns: {#roleId},
) // 反向查询：哪些Node使用了该Role
class RoleUses extends Table {
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();

  TextColumn get roleId =>
      text().references(Roles, #id, onDelete: KeyAction.cascade)();

  // Local fields
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {nodeId, roleId}; // 联合主键自动支持 nodeId -> roleId 的查询
}