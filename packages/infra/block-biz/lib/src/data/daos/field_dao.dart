import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../node_database.dart';
import '../tables/field_refs.dart';
import '../tables/fields.dart';

part 'field_dao.g.dart';

@DriftAccessor(tables: [Fields, FieldRefs])
class FieldDao extends DatabaseAccessor<NodeDatabase> with _$FieldDaoMixin {
  FieldDao(super.db);

  /// 获取某 Trait 下的所有 Fields
  Future<List<FieldEntity>> getFieldsByTrait(String traitId) {
    return (select(fields)..where((t) => t.traitId.equals(traitId))).get();
  }

  /// 监听某 Trait 下的所有 Fields
  Stream<List<FieldEntity>> watchFieldsByTrait(String traitId) {
    return (select(fields)..where((t) => t.traitId.equals(traitId))).watch();
  }

  /// 插入 Field
  Future<int> insertField(FieldsCompanion companion) {
    return into(fields).insert(companion);
  }

  /// 更新 Field 数据 (例如: 用户输入)
  Future<void> updateFieldData(String fieldId, String? data) {
    return (update(fields)..where((t) => t.id.equals(fieldId))).write(
      FieldsCompanion(data: Value(data)), // data 经过 TypeConverter 处理
    );
  }

  /// 更新 Field 配置 (例如: 切换 static/computed 模式)
  Future<void> updateFieldConfig(String fieldId, Map<String, dynamic>? config) {
    return (update(fields)..where((t) => t.id.equals(fieldId))).write(
      FieldsCompanion(config: Value(config)),
    );
  }

  // --- Field Refs ---

  /// 获取某字段的引用列表
  Future<List<FieldRefEntity>> getRefsBySrc(String srcFieldId) {
    return (select(fieldRefs)
          ..where((t) => t.src.equals(srcFieldId))
          ..orderBy([(t) => OrderingTerm(expression: t.rank)]))
        .get();
  }

  /// 插入引用
  Future<int> insertRef(FieldRefsCompanion companion) {
    return into(fieldRefs).insert(companion);
  }

  /// 删除某字段的所有引用 (清理旧引用)
  Future<int> deleteRefsByDst(String dstFieldId) {
    return (delete(fieldRefs)..where((t) => t.dst.equals(dstFieldId))).go();
  }
}

@riverpod
Future<FieldDao> fieldDao(Ref ref) async {
  final db = await ref.watch(nodeDatabaseProvider.future);
  return FieldDao(db);
}
