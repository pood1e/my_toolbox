import 'package:app_core/di.dart';
import 'package:nanoid/nanoid.dart';

import '../../../models/models.dart';
import '../../../repository/node_repository.dart';

part 'node_controller.g.dart';

@riverpod
class NodeController extends _$NodeController {
  @override
  Stream<List<Node>> build() async* {
    final repo = await ref.watch(nodeRepositoryProvider.future);
    yield* repo.watchRecentNodes();
  }

  Future<String> createNode() async {
    final id = nanoid(10);
    final repo = await ref.read(nodeRepositoryProvider.future);
    await repo.createNode(Node(id: id));
    return id;
  }
}
