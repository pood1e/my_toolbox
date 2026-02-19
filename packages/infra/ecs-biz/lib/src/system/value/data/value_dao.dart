import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import '../value_service.dart';
import 'property_val.dart';

part 'value_dao.g.dart';

@DriftAccessor(tables: [PropertyVals])
class ValueDao extends DatabaseAccessor<EcsDatabase> with _$ValueDaoMixin {
  ValueDao(super.attachedDatabase);

  Future<PropertyValEntity?> getValue(PropertyId propertyId) =>
      (select(propertyVals)..where(
            (t) =>
                t.metaId.equals(propertyId.metaId) &
                t.nodeId.equals(propertyId.nodeId),
          ))
          .getSingleOrNull();

  Future<void> setValue(PropertyValsCompanion companion) async {
    await into(propertyVals).insertOnConflictUpdate(companion);
  }

  Future<void> updateStatus(
    PropertyId propertyId,
    ValueStatus status, {
    String? extra,
  }) async {
    final companion = PropertyValsCompanion(
      nodeId: Value(propertyId.nodeId),
      metaId: Value(propertyId.metaId),
      status: Value(status),
      extra: Value(extra),
    );
    await into(propertyVals).insertOnConflictUpdate(companion);
  }

  Future<void> deleteValue(PropertyId propertyId) async {
    final query = delete(propertyVals)
      ..where(
        (t) =>
            t.metaId.equals(propertyId.metaId) &
            t.nodeId.equals(propertyId.nodeId),
      );
    await query.go();
  }
}
