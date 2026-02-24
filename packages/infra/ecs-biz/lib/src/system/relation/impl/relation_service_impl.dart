import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import '../data/relation_dao.dart';
import '../relation_service.dart';

class RelationServiceImpl implements RelationService {
  final RelationDao _dao;

  RelationServiceImpl(this._dao);

  static const int _batchSize = 100;

  @override
  Future<Set<PropertyId>> findAffects(List<PropertyId> srcIds) async {
    if (srcIds.isEmpty) return {};

    final Set<PropertyId> allAffected = {};
    final Set<PropertyId> visited = srcIds.toSet(); // 初始包含起点，防止回环
    List<PropertyId> currentLayer = srcIds.toList();

    // === 核心逻辑：BFS 算法 ===
    while (currentLayer.isNotEmpty) {
      final Set<PropertyId> nextLayerCandidates = {};

      // === 核心策略：分批处理 (Batching) ===
      // Service 层负责将大任务拆解为小任务调用 DAO
      for (var i = 0; i < currentLayer.length; i += _batchSize) {
        final end = (i + _batchSize < currentLayer.length)
            ? i + _batchSize
            : currentLayer.length;
        final batch = currentLayer.sublist(i, end);

        // 调用 DAO 获取数据库原始行 (Row)
        final rows = await _dao.findDirectOutgoingRelations(batch);

        // 转换 Entity -> Domain 并收集
        for (final row in rows) {
          nextLayerCandidates.add(
            PropertyId(nodeId: row.srcNode, metaId: row.srcMeta),
          );
        }
      }

      // === 核心逻辑：去重与准备下一层 ===
      final List<PropertyId> nextLayer = [];
      for (final candidate in nextLayerCandidates) {
        if (!visited.contains(candidate)) {
          visited.add(candidate);
          allAffected.add(candidate);
          nextLayer.add(candidate);
        }
      }

      currentLayer = nextLayer;
    }

    return allAffected.toSet();
  }

  @override
  Future<void> replaceById(
    PropertyId id,
    List<PropertyRelation> relations,
  ) async {
    final companions = relations
        .map(
          (rel) => PropertyRelationsCompanion.insert(
            srcNode: id.nodeId,
            srcMeta: id.metaId,
            dstNode: rel.dst.nodeId,
            dstMeta: rel.dst.metaId,
            affectValue: Value(rel.type.affectValue),
          ),
        )
        .toList();

    await _dao.replaceRelations(id, companions);
  }

  @override
  Future<void> deleteById(PropertyId id) async {
    await _dao.deleteRelationsById(id);
  }

  @override
  Future<void> create(List<PropertyRelation> relations) async {
    final companions = relations
        .map(
          (rel) => PropertyRelationsCompanion.insert(
            srcNode: rel.src.nodeId,
            srcMeta: rel.src.metaId,
            dstNode: rel.dst.nodeId,
            dstMeta: rel.dst.metaId,
            affectValue: Value(rel.type.affectValue),
          ),
        )
        .toList();

    await _dao.createRelations(companions);
  }

  @override
  Stream<Set<PropertyId>> watchAffects(PropertyId id) => _dao
      .watchAffectsCTE(id)
      .map((list) => list.toSet())
      .distinct((prev, next) {
        if (prev.length != next.length) return false;
        return prev.containsAll(next);
      });
}
