import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../../storage/data/nodes.dart';
import '../value_service.dart';

/// 属性值表
/// 本地计算生成
@DataClassName('PropertyValEntity')
class PropertyVals extends Table {
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)(); // NanoID

  TextColumn get metaId => text()();

  BoolColumn get valBool => boolean().nullable()();

  IntColumn get valInt => integer().nullable()();

  RealColumn get valReal => real().nullable()();

  // fst
  TextColumn get valText => text().nullable()();

  TextColumn get valStr => text().nullable()();

  TextColumn get valJson => text().map(const JsonMapConverter()).nullable()();

  TextColumn get status =>
      textEnum<ValueStatus>().withDefault(Constant(ValueStatus.normal.name))();

  TextColumn get extra => text().nullable()();

  @override
  Set<Column> get primaryKey => {nodeId, metaId};
}
