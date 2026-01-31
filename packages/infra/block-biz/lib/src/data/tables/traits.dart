import 'package:drift/drift.dart';

import '../../domain/shared.dart';
import 'nodes.dart';
import 'roles.dart';

@DataClassName('TraitEntity')
@TableIndex(name: 'idx_traits_lookup', columns: {#nodeId, #traitType})
@TableIndex(
  name: 'uidx_traits_full_unique',
  columns: {#traitType, #nodeId, #roleId},
  unique: true,
)
class Traits extends Table {
  TextColumn get id => text()();

  TextColumn get nodeId =>
      text().nullable().references(Nodes, #id, onDelete: KeyAction.cascade)();

  TextColumn get roleId =>
      text().nullable().references(Roles, #id, onDelete: KeyAction.setNull)();

  IntColumn get roleLevel => intEnum<RoleLevel>().nullable()();

  IntColumn get traitType => intEnum<TraitType>()();

  // Local fields
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}