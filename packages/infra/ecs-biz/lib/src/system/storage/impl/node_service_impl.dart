import 'package:app_core/uuid.dart';

import '../data/node_dao.dart';
import '../ecs_database.dart';
import '../node_service.dart';

class NodeServiceImpl implements NodeService {
  final NodeDao _dao;

  NodeServiceImpl({required NodeDao dao}) : _dao = dao;

  @override
  Stream<List<String>> watchNodes([int limit = 10]) =>
      _dao.watchNodes(limit).map((list) => list.map((n) => n.id).toList());

  @override
  Future<String> addNode() async {
    final id = nanoid(10);
    await _dao.insertOne(NodesCompanion.insert(id: id));
    return id;
  }

  @override
  Future<void> deleteNode() {
    // TODO: implement deleteNode
    throw UnimplementedError();
  }
}
