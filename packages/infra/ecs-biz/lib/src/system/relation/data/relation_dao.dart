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

  Selectable<PropertyId> _selectAffectsCTE(PropertyId id) {
    // SQLite 的递归 CTE 语法
    // 注意：Drift 默认会将驼峰字段名转换为下划线，例如 srcNode -> src_node
    const sql = '''
      WITH RECURSIVE traverse(node_id, meta_id) AS (
        -- 1. Base Case (起点): 查找当前节点的直接下游 (只找 affect_value = 1 的)
        SELECT src_node, src_meta
        FROM property_relations
        WHERE dst_node = ? AND dst_meta = ? AND affect_value = 1
        
        UNION 
        -- 注意这里用 UNION 而不是 UNION ALL，SQLite 会自动去重，防止循环图死循环 (A->B->A)
        
        -- 2. Recursive Step (递归): 将上一轮找到的节点作为起点，继续往下找
        SELECT pr.src_node, pr.src_meta
        FROM property_relations pr
        INNER JOIN traverse t ON pr.dst_node = t.node_id AND pr.dst_meta = t.meta_id
        WHERE pr.affect_value = 1
      )
      -- 3. 输出遍历结果
      SELECT node_id, meta_id FROM traverse;
    ''';

    // customSelect 允许执行原生 SQL
    return customSelect(
      sql,
      variables: [
        Variable.withString(id.nodeId),
        Variable.withString(id.metaId),
      ],
      // 【关键】：告诉 Drift 监听 property_relations 表。
      // 一旦该表有增删改，Drift 自动重新执行上述 CTE 并推流！
      readsFrom: {propertyRelations},
    ).map(
      (row) => PropertyId(
        nodeId: row.read<String>('node_id'),
        metaId: row.read<String>('meta_id'),
      ),
    );
  }

  /// 核心：使用 WITH RECURSIVE 在 SQLite 内部完成图的深度遍历
  /// 返回一个可以被 watch 的 Stream！
  Stream<List<PropertyId>> watchAffectsCTE(PropertyId id) =>
      _selectAffectsCTE(id).watch();
}

@riverpod
Future<RelationDao> relationDao(Ref ref) async {
  final db = await ref.watch(ecsDatabaseProvider.future);
  return RelationDao(db);
}
