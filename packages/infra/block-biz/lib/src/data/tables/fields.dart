import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../../domain/shared.dart';
import 'traits.dart';

@DataClassName('FieldEntity')
@TableIndex(name: 'idx_fields_type_search', columns: {#traitType}) // 冗余字段加速搜索
@TableIndex(
  name: 'uidx_fields_full_unique',
  columns: {#traitId, #traitKey},
  unique: true,
)
class Fields extends Table {
  TextColumn get id => text()();

  TextColumn get traitId =>
      text().references(Traits, #id, onDelete: KeyAction.cascade)();

  TextColumn get traitKey => text().withLength(max: 64).nullable()();

  TextColumn get config => text().map(const JsonMapConverter()).nullable()();

  IntColumn get valueType => intEnum<ValueType>()();

  IntColumn get collectionType => intEnum<CollectionType>()();

  BoolColumn get hasRef => boolean().withDefault(const Constant(false))();

  BoolColumn get cacheable => boolean().withDefault(const Constant(true))();

  // Local fields
  IntColumn get traitType => intEnum<TraitType>()(); // 冗余，配合索引加速
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();

  TextColumn get data => text().nullable()();

  BoolColumn get cacheDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
