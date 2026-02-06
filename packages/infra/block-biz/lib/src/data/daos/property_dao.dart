import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../../domain/property.dart';
import '../node_database.dart';
import '../tables/properties.dart';

part 'property_dao.g.dart';

@DriftAccessor(tables: [Properties])
class PropertyDao extends DatabaseAccessor<NodeDatabase>
    with _$PropertyDaoMixin {
  PropertyDao(super.db);

  Expression<bool> _eqKey(PropertyKey key) =>
      properties.nodeId.equals(key.nodeId) & properties.defId.equals(key.defId);

  SimpleSelectStatement<$PropertiesTable, PropertyEntity> _inKeys(
    Set<PropertyKey> keys,
  ) {
    final query = select(properties);

    if (keys.isEmpty) {
      query.where((t) => const Constant(false));
      return query;
    }

    query.where((t) => keys.map(_eqKey).reduce((a, b) => a | b));

    return query;
  }

  Future<List<PropertyEntity>> getProperties(Set<PropertyKey> keys) =>
      _inKeys(keys).get();

  Stream<List<PropertyEntity>> watchProperties(Set<PropertyKey> keys) =>
      _inKeys(keys).watch();

  Stream<PropertyEntity> watchProperty(PropertyKey key) =>
      _inKeys({key}).watchSingle();

  Future<void> saveProperties(List<PropertiesCompanion> companions) async {
    if (companions.isEmpty) return;
    await batch((batch) {
      batch.insertAllOnConflictUpdate(properties, companions);
    });
  }

  Future<void> saveProperty(PropertiesCompanion companion) async {
    await into(properties).insertOnConflictUpdate(companion);
  }

  Future<void> deleteProperty(PropertyKey key) async {
    final query = delete(properties)..where((_) => _eqKey(key));
    await query.go();
  }
}

@riverpod
Future<PropertyDao> propertyDao(Ref ref) async {
  final db = await ref.watch(nodeDatabaseProvider.future);
  return PropertyDao(db);
}
