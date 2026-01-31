import 'package:drift/drift.dart';

import 'roles.dart';

@DataClassName('RoleRefEntity')
@TableIndex(name: 'idx_role_refs_dst', columns: {#dst}) // 反向查询：该Role被谁引用
class RoleRefs extends Table {
  @ReferenceName('src')
  TextColumn get src =>
      text().references(Roles, #id, onDelete: KeyAction.cascade)();

  @ReferenceName('dst')
  TextColumn get dst =>
      text().references(Roles, #id, onDelete: KeyAction.cascade)();

  IntColumn get rank => integer()();

  // Local fields
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {src, dst};
}
