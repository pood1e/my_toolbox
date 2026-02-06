import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../data/daos/node_dao.dart';
import '../data/node_database.dart';
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

// --- Node Mapper ---
extension NodeEntityToDomain on NodeEntity {
  Node toDomain() => Node(id: id);
}

extension NodeDomainToCompanion on Node {
  NodesCompanion toCompanion() => NodesCompanion(id: Value(id));
}
