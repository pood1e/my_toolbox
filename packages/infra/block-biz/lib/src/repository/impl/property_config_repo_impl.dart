import 'package:drift/drift.dart';

import '../../data/daos/complex_compute_dao.dart';
import '../../data/daos/property_atom_config_dao.dart';
import '../../data/node_database.dart';
import '../../data/tables/property_config.dart';
import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../../mappers/property_config_mapper.dart';
import '../property_config_repository.dart';

class PropertyConfigRepoImpl extends PropertyConfigRepository {
  final PropertyAtomConfigDao _dao;
  final ComplexComputeDao _computeDao;

  PropertyConfigRepoImpl({
    required PropertyAtomConfigDao dao,
    required ComplexComputeDao computeDao,
  }) : _dao = dao,
       _computeDao = computeDao;

  @override
  Stream<PropertyConfig> watchConfig(PropertyKey key) =>
      _dao.watchByKey(key).map((rows) => rows.toDomain(key));

  @override
  Future<void> fullUpdate(PropertyConfig config) => _dao.transaction(() async {
    // 1. 查 DB 现状
    final currentRows = await _dao.getByKey(config.key);

    // 2. Diff 计算 (使用 Extension 1 转 Record，Extension 2 做 Diff)
    final changes = config.diff(currentRows.toRecords());

    // 3. 执行
    if (changes.isNotEmpty) {
      await batchUpdate(changes);
    }
  });

  @override
  Future<void> batchUpdate(List<ParticalConfigChange> changes) async {
    if (changes.isEmpty) return;

    final affectedKeys = <PropertyKey>{};

    await _dao.transaction(() async {
      for (final change in changes) {
        final key = await _applyChange(change);
        if (key != null) {
          affectedKeys.add(key);
        }
      }

      if (affectedKeys.isNotEmpty) {
        await _notifyAffectedKeys(affectedKeys);
      }
    });
  }

  Future<PropertyKey?> _applyChange(ParticalConfigChange change) async {
    final tbl = _dao.propertyAtomConfigs;

    // 提取 Key 和 Record (Helper)
    final (infoKey, record) = change.map(
      insert: (c) => (c.key, c.record),
      update: (c) => (c.key, c.record),
      delete: (c) => (c.key, null),
    );

    final propKey = PropertyKey(nodeId: infoKey.nodeId, defId: infoKey.refId);

    // 构建 Where 子句
    Expression<bool> whereClause(PropertyAtomConfigs t) =>
        t.nodeId.equals(infoKey.nodeId) &
        t.defId.equals(infoKey.refId) &
        (infoKey.configKey == null
            ? t.configKey.isNull()
            : t.configKey.equals(infoKey.configKey!)) &
        (infoKey.mapKey == null
            ? t.mapKey.isNull()
            : t.mapKey.equals(infoKey.mapKey!));

    bool isDirty = false;

    // 执行 DB 操作并检查 isDirty (使用 Extension 3)
    await change.map(
      insert: (c) async {
        // Insert: oldAffectValue 隐式为 null
        isDirty = change.isDirty(null);

        await _dao
            .into(tbl)
            .insert(
              PropertyAtomConfigsCompanion.insert(
                nodeId: infoKey.nodeId,
                defId: infoKey.refId,
                configKey: Value(infoKey.configKey),
                mapKey: Value(infoKey.mapKey),
                targetNodeId: Value(c.record.targetNodeId),
                targetDefId: Value(c.record.targetDefId),
                config: Value(c.record.config),
                affectValue: Value(c.record.affectValue),
              ),
            );
      },
      update: (c) async {
        // Update: 需要查旧值
        final oldRow = await (_dao.select(
          tbl,
        )..where(whereClause)).getSingleOrNull();
        if (oldRow != null) {
          isDirty = change.isDirty(oldRow.affectValue);

          await (_dao.update(tbl)..where(whereClause)).write(
            PropertyAtomConfigsCompanion(
              targetNodeId: Value(c.record.targetNodeId),
              targetDefId: Value(c.record.targetDefId),
              config: Value(c.record.config),
              affectValue: Value(c.record.affectValue),
            ),
          );
        }
      },
      delete: (c) async {
        // Delete: 需要查旧值
        final oldRow = await (_dao.select(
          tbl,
        )..where(whereClause)).getSingleOrNull();
        if (oldRow != null) {
          isDirty = change.isDirty(oldRow.affectValue);
          await (_dao.delete(tbl)..where(whereClause)).go();
        }
      },
    );

    return isDirty ? propKey : null;
  }

  Future<void> _notifyAffectedKeys(Set<PropertyKey> keys) =>
      _computeDao.markDirtyRecursive(rootKeys: keys);

  @override
  Stream<List<PropertyKey>> watchNodeKeys(String nodeId) =>
      _dao.watchNode(nodeId);
}
