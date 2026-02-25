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

    // === 核心逻辑优化 ===
    // 依然保留分批，防止 SQLite 参数报错
    for (var i = 0; i < srcIds.length; i += _batchSize) {
      final end = (i + _batchSize < srcIds.length)
          ? i + _batchSize
          : srcIds.length;
      final batch = srcIds.sublist(i, end);

      // 调用支持批量起点的 CTE
      // 这一步虽然只发了一次 SQL，但已经在数据库内部把这 100 个起点的所有下游全部找完了！
      final batchResults = await _dao.getAffectsCTEBatch(batch);

      allAffected.addAll(batchResults);
    }

    return allAffected;
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
  Stream<Set<PropertyId>> watchAffects(PropertyId id) =>
      _dao.watchAffectsCTE(id).distinct((prev, next) {
        if (prev.length != next.length) return false;
        return prev.containsAll(next);
      });
}
