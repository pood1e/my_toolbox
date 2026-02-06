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

  Expression<bool> _eqKey(PropertyKey key) =>
      propertyAtomConfigs.nodeId.equals(key.nodeId) &
      propertyAtomConfigs.defId.equals(key.defId);

  SimpleSelectStatement<$PropertyAtomConfigsTable, PropertyAtomConfigEntity>
  _inKeys(Set<PropertyKey> keys) {
    final query = select(propertyAtomConfigs);

    if (keys.isEmpty) {
      query.where((t) => const Constant(false));
      return query;
    }

    query.where((t) => keys.map(_eqKey).reduce((a, b) => a | b));

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

  Future<List<PropertyAtomConfigEntity>> getByKeys(Set<PropertyKey> keys) =>
      _inKeys(keys).get();

  Future<List<PropertyAtomConfigEntity>> getByKey(PropertyKey key) =>
      _inKeys({key}).get();

  Stream<List<PropertyAtomConfigEntity>> watchByKey(PropertyKey key) =>
      _inKeys({key}).watch();

  Future<void> deleteConfig(PropertyKey key) async {
    final query = delete(propertyAtomConfigs)..where((_) => _eqKey(key));
    await query.go();
  }
}

@riverpod
Future<PropertyAtomConfigDao> propertyAtomConfigDao(Ref ref) async {
  final db = await ref.watch(nodeDatabaseProvider.future);
  return PropertyAtomConfigDao(db);
}
