import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import '../value_service.dart';
import 'property_val.dart';

part 'value_dao.g.dart';

@DriftAccessor(tables: [PropertyVals])
class ValueDao extends DatabaseAccessor<EcsDatabase> with _$ValueDaoMixin {
  ValueDao(super.attachedDatabase);

  SimpleSelectStatement<$PropertyValsTable, PropertyValEntity> _selectByIds(
    Set<PropertyId> ids,
  ) => select(propertyVals)
    ..where(
      (t) => ids
          .map((id) => t.metaId.equals(id.metaId) & t.nodeId.equals(id.nodeId))
          .reduce((a, b) => a | b),
    );

  Future<PropertyValEntity?> getValue(PropertyId propertyId) =>
      _selectByIds({propertyId}).getSingleOrNull();

  Future<List<PropertyValEntity>> getValuesList(Set<PropertyId> ids) async {
    if (ids.isEmpty) return [];
    return _selectByIds(ids).get();
  }

  Stream<List<PropertyValEntity>> watchValuesList(Set<PropertyId> ids) async* {
    if (ids.isEmpty) {
      yield <PropertyValEntity>[];
    } else {
      yield* _selectByIds(ids).watch();
    }
  }

  Stream<PropertyValEntity?> watchValue(PropertyId propertyId) =>
      _selectByIds({propertyId}).watchSingleOrNull();

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

@riverpod
Future<ValueDao> valueDao(Ref ref) async {
  final db = await ref.watch(ecsDatabaseProvider.future);
  return ValueDao(db);
}
