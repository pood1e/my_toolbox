import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../node_database.dart';
import '../tables/nodes.dart';

part 'node_dao.g.dart';

@DriftAccessor(tables: [Nodes])
class NodeDao extends DatabaseAccessor<NodeDatabase> with _$NodeDaoMixin {
  NodeDao(super.db);

  /// 监听节点列表 (支持 limit)
  Stream<List<NodeEntity>> watchNodes({int limit = 20}) =>
      (select(nodes)..limit(limit)).watch();

  /// 获取单个节点
  Future<NodeEntity?> getNode(String id) =>
      (select(nodes)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 插入或替换
  Future<int> insertNode(NodesCompanion companion) =>
      into(nodes).insertOnConflictUpdate(companion);
}

@riverpod
Future<NodeDao> nodeDao(Ref ref) async {
  final db = await ref.watch(nodeDatabaseProvider.future);
  return NodeDao(db);
}
