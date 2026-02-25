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
  _selectByNodeAndMeta(List<PropertyId> ids) {
    final query = select(propertyConfigs);
    if (ids.isEmpty) {
      // 如果 ID 为空，直接加上一个绝对为 false 的条件，让查询返回空结果而不崩溃
      query.where((t) => const Constant(false));
      return query;
    }
    return query
      ..where(
        (t) => ids
            .map(
              (id) => t.metaId.equals(id.metaId) & t.nodeId.equals(id.nodeId),
            )
            .reduce((a, b) => a | b),
      )
      ..where((t) => t.deletedAt.isNull());
  }

  // 通过联合主键查找
  Future<PropertyConfigEntity?> findByNodeAndMeta(PropertyId propertyId) =>
      _selectByNodeAndMeta([propertyId]).getSingleOrNull();

  Stream<PropertyConfigEntity?> watchByProperty(PropertyId propertyId) =>
      _selectByNodeAndMeta([propertyId]).watchSingleOrNull();

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

  Future<void> updateConfig(
    PropertyId propertyId,
    PropertyConfigsCompanion companion,
  ) async {
    final query = update(propertyConfigs)
      ..where(
        (t) =>
            t.nodeId.equals(propertyId.nodeId) &
            t.metaId.equals(propertyId.metaId),
      );
    await query.write(companion);
  }

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

  /// 批量检查属性是否存在（自动过滤已软删除的数据）
  Future<Set<PropertyId>> checkExist(Set<PropertyId> propertyIds) async {
    if (propertyIds.isEmpty) return {};

    final Set<PropertyId> existingIds = {};
    final idsList = propertyIds.toList();

    // 分批处理，防止传入巨量 ID 时，SQLite 的 OR 表达式超过最大限制导致崩溃
    const int batchSize = 100;

    for (var i = 0; i < idsList.length; i += batchSize) {
      final end = (i + batchSize < idsList.length)
          ? i + batchSize
          : idsList.length;
      final batch = idsList.sublist(i, end);

      // 性能优化：使用 selectOnly 只查出所需的复合主键字段，而不拉取整行数据
      final query = selectOnly(propertyConfigs)
        ..addColumns([propertyConfigs.nodeId, propertyConfigs.metaId])
        ..where(propertyConfigs.deletedAt.isNull())
        ..where(
          batch
              .map(
                (id) =>
                    propertyConfigs.nodeId.equals(id.nodeId) &
                    propertyConfigs.metaId.equals(id.metaId),
              )
              .reduce((a, b) => a | b),
        );

      final rows = await query.get();

      existingIds.addAll(
        rows.map(
          (row) => PropertyId(
            nodeId: row.read(propertyConfigs.nodeId)!,
            metaId: row.read(propertyConfigs.metaId)!,
          ),
        ),
      );
    }

    return existingIds;
  }
}

@riverpod
Future<PropertyConfigsDao> propertyConfigDao(Ref ref) async {
  final db = await ref.watch(ecsDatabaseProvider.future);
  return PropertyConfigsDao(db);
}
