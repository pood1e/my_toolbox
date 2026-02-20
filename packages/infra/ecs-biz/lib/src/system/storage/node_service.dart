import 'package:app_core/di.dart';

import 'data/node_dao.dart';
import 'impl/node_service_impl.dart';

part 'node_service.g.dart';

abstract class NodeService {
  Stream<List<String>> watchNodes([int limit = 10]);

  Future<String> addNode();

  Future<void> deleteNode();
}

@riverpod
Future<NodeService> nodeService(Ref ref) async {
  final dao = await ref.watch(nodeDaoProvider.future);
  return NodeServiceImpl(dao: dao);
}
