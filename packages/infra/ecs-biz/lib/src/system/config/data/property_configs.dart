import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../../storage/data/nodes.dart';

/// 节点属性配置
@DataClassName('PropertyConfigEntity')
class PropertyConfigs extends Table
    with
        UpdatedAtTableMixin,
        DeletedAtTableMixin,
        IsDirtySyncTableMixin,
        CursorSyncTableMixin {
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)(); // NanoID

  TextColumn get metaId => text()();

  TextColumn get config => text().map(const JsonMapConverter())();

  @override
  Set<Column> get primaryKey => {nodeId, metaId};
}
