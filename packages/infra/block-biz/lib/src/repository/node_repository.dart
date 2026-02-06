import 'package:app_core/di.dart';

import '../data/daos/node_dao.dart';
import '../data/mappers.dart';
import '../domain/node.dart';

part 'node_repository.g.dart';

class NodeRepository {
  final NodeDao _dao;

  NodeRepository(this._dao);

  Stream<List<Node>> watchRecentNodes() {
    return _dao.watchNodes().map(
      (entities) => entities.map((e) => e.toDomain()).toList(),
    );
  }

  Future<void> createNode(Node node) async {
    await _dao.insertNode(node.toCompanion());
  }

}

@riverpod
Future<NodeRepository> nodeRepository(Ref ref) async {
  final dao = await ref.watch(nodeDaoProvider.future);
  return NodeRepository(dao);
}
