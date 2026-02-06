import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../../domain/property.dart';
import '../node_database.dart';
import '../tables/property_config.dart';

part 'property_atom_config_dao.g.dart';

@DriftAccessor(tables: [PropertyAtomConfigs])
class PropertyAtomConfigDao extends DatabaseAccessor<NodeDatabase>
    with _$PropertyAtomConfigDaoMixin {
  PropertyAtomConfigDao(super.db);

  SimpleSelectStatement<$PropertyAtomConfigsTable, PropertyAtomConfigEntity>
  _selectStatement(List<PropertyKey> keys) {
    final query = select(propertyAtomConfigs);

    if (keys.isEmpty) {
      query.where((t) => const Constant(false));
      return query;
    }

    query.where(
      (t) => keys
          .map((key) => t.nodeId.equals(key.nodeId) & t.defId.equals(key.defId))
          .reduce((a, b) => a | b),
    );

    return query;
  }

  Stream<List<PropertyKey>> watchNode(String nodeId) {
    final query = selectOnly(propertyAtomConfigs)
      ..addColumns([propertyAtomConfigs.defId])
      ..where(propertyAtomConfigs.nodeId.equals(nodeId));
    return query.watch().map(
      (list) => list
          .map(
            (row) => PropertyKey(
              nodeId: nodeId,
              defId: row.read(propertyAtomConfigs.defId)!,
            ),
          )
          .toList(),
    );
  }

  Future<List<PropertyAtomConfigEntity>> getByKeys(
    List<PropertyKey> keys,
  ) async {
    final query = _selectStatement(keys);
    return query.get();
  }

  Future<List<PropertyAtomConfigEntity>> getByKey(PropertyKey key) async {
    final query = _selectStatement([key]);
    return query.get();
  }

  Stream<List<PropertyAtomConfigEntity>> watchByKey(PropertyKey key) {
    final query = _selectStatement([key]);
    return query.watch();
  }
}

@riverpod
Future<PropertyAtomConfigDao> propertyAtomConfigDao(Ref ref) async {
  final db = await ref.watch(nodeDatabaseProvider.future);
  return PropertyAtomConfigDao(db);
}
