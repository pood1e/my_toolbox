import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../node_database.dart';
import '../tables/traits.dart';

part 'trait_dao.g.dart';

@DriftAccessor(tables: [Traits])
class TraitDao extends DatabaseAccessor<NodeDatabase> with _$TraitDaoMixin {
  TraitDao(super.db);

  SimpleSelectStatement<$TraitsTable, TraitEntity> _queryByNodeId(
    String nodeId,
  ) {
    return select(traits)
      ..where((t) => t.nodeId.equals(nodeId))
      ..orderBy([(t) => OrderingTerm(expression: t.traitType)]);
  }

  /// 监听某 Node 下的所有 Traits
  Stream<List<TraitEntity>> watchTraitsByNode(String nodeId) {
    return _queryByNodeId(nodeId).watch();
  }

  /// 监听某 Node 下的所有 Traits
  Future<List<TraitEntity>> getTraitsByNode(String nodeId) {
    return _queryByNodeId(nodeId).get();
  }

  /// 获取单个 Trait
  Future<TraitEntity?> getTrait(String id) {
    return (select(traits)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTrait(TraitsCompanion companion) {
    return into(traits).insert(companion);
  }

  Future<int> deleteTrait(String id) {
    return (delete(traits)..where((t) => t.id.equals(id))).go();
  }
}

@riverpod
Future<TraitDao> traitDao(Ref ref) async {
  final db = await ref.watch(nodeDatabaseProvider.future);
  return TraitDao(db);
}
