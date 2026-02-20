import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import 'property_configs.dart';

part 'property_config_dao.g.dart';

@DriftAccessor(tables: [PropertyConfigs])
class PropertyConfigsDao extends DatabaseAccessor<EcsDatabase>
    with _$PropertyConfigsDaoMixin {
  PropertyConfigsDao(super.attachedDatabase);

  SimpleSelectStatement<$PropertyConfigsTable, PropertyConfigEntity>
  _selectByNodeAndMeta(List<PropertyId> ids) => select(propertyConfigs)
    ..where(
      (t) => ids
          .map((id) => t.metaId.equals(id.metaId) & t.nodeId.equals(id.nodeId))
          .reduce((a, b) => a | b),
    )
    ..where((t) => t.deletedAt.isNull());

  // 通过联合主键查找
  Future<PropertyConfigEntity?> findByNodeAndMeta(PropertyId propertyId) =>
      _selectByNodeAndMeta([propertyId]).getSingleOrNull();

  Stream<PropertyConfigEntity?> watchByProperty(PropertyId propertyId) =>
      _selectByNodeAndMeta([propertyId]).watchSingle();

  Stream<Set<String>> watchPropertiesByNode(String nodeId) {
    final query = selectOnly(propertyConfigs)
      ..addColumns([propertyConfigs.metaId])
      ..where(propertyConfigs.nodeId.equals(nodeId))
      ..where(propertyConfigs.deletedAt.isNull());
    return query.watch().map(
      (rows) =>
          rows.map((typed) => typed.read(propertyConfigs.metaId)!).toSet(),
    );
  }

  Future<int> insertConfig(PropertyConfigsCompanion companion) =>
      into(propertyConfigs).insertOnConflictUpdate(companion);

  Future<bool> updateConfig(PropertyConfigsCompanion companion) =>
      update(propertyConfigs).replace(companion);

  Future<int> softDeleteById(PropertyId propertyId, int deletedAt) =>
      (update(propertyConfigs)..where(
            (t) =>
                t.nodeId.equals(propertyId.nodeId) &
                t.metaId.equals(propertyId.metaId),
          ))
          .write(
            PropertyConfigsCompanion(
              deletedAt: Value(deletedAt),
              isDirty: const Value(true), // 删除通常也视为脏数据需要同步
            ),
          );
}

@riverpod
Future<PropertyConfigsDao> propertyConfigDao(Ref ref) async {
  final db = await ref.watch(ecsDatabaseProvider.future);
  return PropertyConfigsDao(db);
}
