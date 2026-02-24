import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import '../../value/data/property_val.dart';

part 'search_dao.g.dart';

@DriftAccessor(tables: [PropertyVals])
class SearchDao extends DatabaseAccessor<EcsDatabase> with _$SearchDaoMixin {
  SearchDao(super.attachedDatabase);

  Stream<Set<PropertyId>> watchPropertiesByMetas(Set<String> metaIds) {
    final query = selectOnly(propertyVals)
      ..addColumns([propertyVals.metaId, propertyVals.nodeId])
      ..where(
        metaIds
            .map((id) => propertyVals.metaId.equals(id))
            .reduce((a, b) => a | b),
      );
    return query.watch().map(
      (rows) => rows
          .map(
            (typed) => PropertyId(
              nodeId: typed.read(propertyVals.nodeId)!,
              metaId: typed.read(propertyVals.metaId)!,
            ),
          )
          .toSet(),
    );
  }
}

@riverpod
Future<SearchDao> searchDao(Ref ref) async {
  final db = await ref.watch(ecsDatabaseProvider.future);
  return SearchDao(db);
}
