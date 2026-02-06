import 'package:drift/drift.dart';

import '../../domain/stored_value.dart';
import 'nodes.dart';

/// 属性值表
/// 本地计算生成
@DataClassName('PropertyEntity')
class Properties extends Table {
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)(); // NanoID

  /// 属性定义id
  TextColumn get defId => text()();

  BoolColumn get valBool => boolean().nullable()();

  IntColumn get valInt => integer().nullable()();

  RealColumn get valReal => real().nullable()();

  TextColumn get valText => text().nullable()();

  TextColumn get valJson => text().nullable()();

  IntColumn get valueStatus =>
      intEnum<ValueStatus>().withDefault(Constant(ValueStatus.normal.index))();

  IntColumn get errorType => intEnum<ValueError>().nullable()();

  @override
  Set<Column> get primaryKey => {nodeId, defId};
}
