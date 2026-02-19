import 'package:drift/drift.dart';

import '../../storage/tables/nodes.dart';

@DataClassName('PropertyRelationEntity')
class PropertyRelations extends Table {
  @ReferenceName('srcNode')
  TextColumn get srcNode =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();

  TextColumn get srcMeta => text()();

  @ReferenceName('dstNode')
  TextColumn get dstNode =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();

  TextColumn get dstMeta => text()();

  BoolColumn get affectValue => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {srcNode, srcMeta, dstNode, dstMeta};
}
