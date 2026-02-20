import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../ecs_database.dart';
import 'nodes.dart';

part 'node_dao.g.dart';

@DriftAccessor(tables: [Nodes])
class NodeDao extends DatabaseAccessor<EcsDatabase> with _$NodeDaoMixin {
  NodeDao(super.db);

  Stream<List<NodeEntity>> watchNodes([int limit = 10]) {
    final query = select(nodes)..limit(limit);
    return query.watch();
  }

  Future<void> insertOne(NodesCompanion companion) async {
    await into(nodes).insert(companion);
  }
}

@riverpod
Future<NodeDao> nodeDao(Ref ref) async {
  final db = await ref.watch(ecsDatabaseProvider.future);
  return NodeDao(db);
}
