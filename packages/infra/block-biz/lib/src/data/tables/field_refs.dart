import 'package:drift/drift.dart';

import 'fields.dart';

@DataClassName('FieldRefEntity')
@TableIndex(
  name: 'idx_field_refs_dst',
  columns: {#dst},
) // 反向查询：该字段被谁引用（用于脏检查传播）
class FieldRefs extends Table {
  @ReferenceName('src')
  TextColumn get src =>
      text().references(Fields, #id, onDelete: KeyAction.cascade)();

  @ReferenceName('dst')
  TextColumn get dst =>
      text().references(Fields, #id, onDelete: KeyAction.cascade)();

  IntColumn get rank => integer().nullable()();

  TextColumn get fieldKey => text().withLength(max: 64).nullable()();

  @override
  Set<Column> get primaryKey => {src, dst};
}
