import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../node_database.dart';
import '../tables/nodes.dart';

part 'node_dao.g.dart';

@DriftAccessor(tables: [Nodes])
class NodeDao extends DatabaseAccessor<NodeDatabase> with _$NodeDaoMixin {
  NodeDao(super.db);

  /// 监听节点列表 (支持 limit)
  Stream<List<NodeEntity>> watchNodes({int limit = 20}) {
    return (select(nodes)..limit(limit)
        // 可以在这里添加默认排序，例如按 ID 或创建时间
        )
        .watch();
  }

  /// 获取单个节点
  Future<NodeEntity?> getNode(String id) {
    return (select(nodes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 插入或替换
  Future<int> insertNode(NodesCompanion companion) {
    return into(nodes).insertOnConflictUpdate(companion);
  }

  /// 删除节点
  Future<int> deleteNode(String id) {
    return (delete(nodes)..where((t) => t.id.equals(id))).go();
  }
}

@riverpod
Future<NodeDao> nodeDao(Ref ref) async {
  final db = await ref.watch(nodeDatabaseProvider.future);
  return NodeDao(db);
}
