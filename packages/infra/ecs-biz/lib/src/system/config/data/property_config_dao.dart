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
  _selectByNodeAndMeta(PropertyId propertyId) => select(propertyConfigs)
    ..where(
      (t) =>
          t.nodeId.equals(propertyId.nodeId) &
          t.metaId.equals(propertyId.metaId),
    );

  // 通过联合主键查找
  Future<PropertyConfigEntity?> findByNodeAndMeta(PropertyId propertyId) =>
      _selectByNodeAndMeta(propertyId).getSingleOrNull();

  Future<int> insertConfig(PropertyConfigsCompanion companion) =>
      into(propertyConfigs).insert(companion);

  Future<bool> updateConfig(PropertyConfigsCompanion companion) =>
      update(propertyConfigs).replace(companion);

  Future<int> softDeleteById(PropertyId propertyId, int deletedAt) =>
      (update(propertyConfigs)..where(
            (t) =>
                t.nodeId.equals(propertyId.metaId) &
                t.metaId.equals(propertyId.metaId),
          ))
          .write(
            PropertyConfigsCompanion(
              deletedAt: Value(deletedAt),
              isDirty: const Value(true), // 删除通常也视为脏数据需要同步
            ),
          );
}
