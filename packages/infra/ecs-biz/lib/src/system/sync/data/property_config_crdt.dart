import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../../storage/tables/nodes.dart';

// crdt
@DataClassName('PropertyConfigCrdtEntity')
class PropertyConfigCrdts extends Table
    with UpdatedAtTableMixin, DeletedAtTableMixin {
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)(); // NanoID

  TextColumn get metaId => text()();

  TextColumn get syncKey => text()();

  @override
  Set<Column> get primaryKey => {nodeId, metaId, syncKey};
}
