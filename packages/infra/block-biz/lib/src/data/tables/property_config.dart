import 'package:drift/drift.dart';

import 'nodes.dart';

/// 节点属性配置
@DataClassName('PropertyAtomConfigEntity')
class PropertyAtomConfigs extends Table {
  @ReferenceName('source')
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)(); // NanoID

  /// 属性定义id
  TextColumn get defId => text()();

  /// 属性配置key
  TextColumn get configKey => text().nullable()();

  /// map/list 使用
  TextColumn get mapKey => text().nullable()();

  @ReferenceName('target')
  /// 引用时使用
  TextColumn get targetNodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.setNull).nullable()();

  TextColumn get targetDefId => text().nullable()();

  BoolColumn get affectValue => boolean().withDefault(const Constant(true))();

  /// 具体配置
  TextColumn get config => text().nullable()();


  @override
  Set<Column> get primaryKey => {nodeId, defId, configKey, mapKey};
}
