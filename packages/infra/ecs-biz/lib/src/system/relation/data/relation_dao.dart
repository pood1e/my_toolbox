// relation_dao.dart
import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import 'property_relations.dart';

part 'relation_dao.g.dart';

@DriftAccessor(tables: [PropertyRelations])
class RelationDao extends DatabaseAccessor<EcsDatabase>
    with _$RelationDaoMixin {
  RelationDao(super.db);

  /// 基础查询：查找一批 srcId 对应的、且 affectValue=true 的下游节点。
  /// 注意：调用者需保证 [batchIds] 的数量不会导致 SQL 超长 (建议 < 100)。
  Future<List<PropertyRelationEntity>> findDirectOutgoingRelations(
    List<PropertyId> batchIds,
  ) async {
    if (batchIds.isEmpty) return [];

    // 构建 (srcNode=A AND srcMeta=B) OR ...
    final predicate = batchIds
        .map(
          (id) =>
              propertyRelations.dstNode.equals(id.nodeId) &
              propertyRelations.dstMeta.equals(id.metaId),
        )
        .reduce((a, b) => a | b);

    return (select(propertyRelations)
          ..where((t) => t.affectValue.equals(true)) // 只查 affectValue=true
          ..where((t) => predicate))
        .get();
  }

  /// 事务操作：替换某个 ID 的所有关系
  /// 接收数据库层面的 Companion 对象
  Future<void> replaceRelations(
    PropertyId srcId,
    List<PropertyRelationsCompanion> newRelations,
  ) async {
    await batch((batch) {
      // 1. 删除旧数据
      batch.deleteWhere(
        propertyRelations,
        (t) => t.srcNode.equals(srcId.nodeId) & t.srcMeta.equals(srcId.metaId),
      );

      // 2. 插入新数据
      batch.insertAll(propertyRelations, newRelations);
    });
  }

  Future<void> createRelations(
    List<PropertyRelationsCompanion> newRelations,
  ) async {
    await batch((batch) {
      batch.insertAll(propertyRelations, newRelations);
    });
  }

  /// 基础删除
  Future<void> deleteRelationsById(PropertyId id) async {
    await (delete(propertyRelations)..where(
          (t) =>
              (t.srcNode.equals(id.nodeId) & t.srcMeta.equals(id.metaId)) |
              (t.dstNode.equals(id.nodeId) & t.dstMeta.equals(id.metaId)),
        ))
        .go();
  }
}

@riverpod
Future<RelationDao> relationDao(Ref ref) async {
  final db = await ref.watch(ecsDatabaseProvider.future);
  return RelationDao(db);
}
