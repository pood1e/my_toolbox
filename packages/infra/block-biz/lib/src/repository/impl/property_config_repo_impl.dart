import 'package:drift/drift.dart';

import '../../data/daos/complex_compute_dao.dart';
import '../../data/daos/property_atom_config_dao.dart';
import '../../data/daos/property_dao.dart';
import '../../data/node_database.dart';
import '../../data/tables/property_config.dart';
import '../../domain/config_spec.dart';
import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../../domain/stored_value.dart';
import '../../mappers/property_config_mapper.dart';
import '../property_config_repository.dart';

class PropertyConfigRepoImpl extends PropertyConfigRepository {
  final PropertyAtomConfigDao _dao;
  final ComplexComputeDao _computeDao;
  final PropertyDao _propertyDao;
  final Map<String, ConfigSpecDescriptor> _descriptorMap;

  PropertyConfigRepoImpl({
    required PropertyAtomConfigDao dao,
    required ComplexComputeDao computeDao,
    required PropertyDao propertyDao,
    required Map<String, ConfigSpecDescriptor> descriptorMap,
  }) : _dao = dao,
       _computeDao = computeDao,
       _propertyDao = propertyDao,
       _descriptorMap = descriptorMap;

  // --- Read Operations ---

  @override
  Stream<PropertyConfig?> watchConfig(PropertyKey key) =>
      _dao.watchByKey(key).map((rows) {
        if (rows.isEmpty) return null;
        final storedList = rows.toStoredList();
        return PropertyConfigParser.parse(key, storedList, _descriptorMap);
      });

  @override
  Stream<Set<PropertyKey>> watchNodeKeys(String nodeId) =>
      _dao.watchNode(nodeId).map((list) => list.toSet());

  // --- Write Operations ---

  /// 全量更新 (Full Update)
  /// 适用于：模式切换、表单保存、初始化默认值
  @override
  Future<void> fullUpdate(PropertyConfig config) => _dao.transaction(() async {
    // 1. 获取当前 DB 中的扁平记录
    final currentEntities = await _dao.getByKey(config.key);
    final currentRecords = currentEntities
        .map((e) => e.toStoredConfig())
        .toList();

    // 2. 将新的多态 Config 拍扁
    final newRecords = config.toStoredConfigs();

    // 3. 计算 Diff (Insert/Update/Delete)
    final changes = currentRecords.diffTo(config.key, newRecords);

    // 4. 执行更新
    if (changes.isNotEmpty) {
      await _executeBatch(changes);
    }
  });

  /// 局部更新 (Partial Update)
  /// 适用于：UI 上的单个开关、文本框的实时修改
  @override
  Future<void> particalUpdate(ParticalConfigChange change) async {
    await batchUpdate([change]);
  }

  /// 批量更新 (Batch Update)
  /// 底层入口，处理事务和脏标记
  @override
  Future<void> batchUpdate(List<ParticalConfigChange> changes) async {
    if (changes.isEmpty) return;
    await _dao.transaction(() async {
      await _executeBatch(changes);
    });
  }

  /// 内部执行逻辑 (必须在事务中调用)
  Future<void> _executeBatch(List<ParticalConfigChange> changes) async {
    final affectedRootKeys = <PropertyKey>{};

    for (final change in changes) {
      // 1. 应用 SQL 变更
      final key = await _applyChangeToDb(change);

      // 2. 收集受影响的 Key
      if (key != null) {
        affectedRootKeys.add(key);
      }
    }

    // 3. 触发脏标记传播
    // 只需要标记 Root (即被修改的属性本身)，
    // ComplexComputeDao.markDirtyRecursive 会负责将标记传播给所有依赖它的下游节点。
    if (affectedRootKeys.isNotEmpty) {
      await _computeDao.markDirtyRecursive(
        rootKeys: affectedRootKeys,
        includeSelf: true, // 自身配置变了，自身的值大概率也脏了
      );
    }
  }

  /// 将单个 Change 映射为 Drift 的 SQL 操作
  /// 返回值: 如果操作导致数据变更，返回对应的 PropertyKey；否则返回 null
  Future<PropertyKey?> _applyChangeToDb(ParticalConfigChange change) async {
    final tbl = _dao.propertyAtomConfigs;

    // 提取通用 Key 信息
    final (keyInfo, record) = change.map(
      insert: (c) => (c.key, c.record),
      update: (c) => (c.key, c.record),
      delete: (c) => (c.key, null),
    );

    final propKey = PropertyKey(nodeId: keyInfo.nodeId, defId: keyInfo.refId);

    // 构建 Where 条件: (nodeId, defId, configKey, mapKey)
    Expression<bool> whereClause(PropertyAtomConfigs t) {
      var expr =
          t.nodeId.equals(keyInfo.nodeId) & t.defId.equals(keyInfo.refId);

      expr &= t.configType.equals(keyInfo.configType.name);

      if (keyInfo.mapKey != null) {
        expr &= t.mapKey.equals(keyInfo.mapKey!);
      } else {
        expr &= t.mapKey.isNull();
      }
      return expr;
    }

    // 执行 SQL
    // 注意：这里我们假设 diff 逻辑是准确的，因此直接执行。
    // 如果需要更严格的脏检查（比如 affectValue 从 false 变成 false），可以在这里判断。
    // 但通常配置变了都算脏。

    await change.map(
      insert: (c) async {
        await _dao
            .into(tbl)
            .insert(
              PropertyAtomConfigsCompanion.insert(
                nodeId: keyInfo.nodeId,
                defId: keyInfo.refId,
                configType: keyInfo.configType,
                // Insert 时 key 不能为空，根据 schema 定义调整
                mapKey: Value(keyInfo.mapKey),
                targetNodeId: Value(c.record.targetNodeId),
                targetDefId: Value(c.record.targetDefId),
                config: Value(c.record.config),
                affectValue: Value(c.record.affectValue),
              ),
            );
      },
      update: (c) async {
        await (_dao.update(tbl)..where(whereClause)).write(
          PropertyAtomConfigsCompanion(
            targetNodeId: Value(c.record.targetNodeId),
            targetDefId: Value(c.record.targetDefId),
            config: Value(c.record.config),
            affectValue: Value(c.record.affectValue),
          ),
        );
      },
      delete: (c) async {
        await (_dao.delete(tbl)..where(whereClause)).go();
      },
    );

    // 对于 Delete 操作，如果原本不存在，affected 也是 false，但 Diff 算法保证了存在才 Delete。
    // 这里简单返回 Key，表示此属性发生了结构变更。
    return propKey;
  }

  @override
  Future<void> deleteConfig(PropertyKey key) => _dao.transaction(() async {
    // 1. 先标记错误 (因为该节点即将消失，依赖它的节点会变成 Ref Error)
    // includeSelf: false -> 标记下游，不标记自己(因为自己马上要没了)
    await _computeDao.markErrorRecursive(
      rootKeys: {key},
      rootError: ValueError.referenceInvalid, // 下游会因为找不到引用而报错
      includeSelf: false,
    );

    // 2. 删除配置
    await _dao.deleteConfig(key);

    // 3. 删除缓存的值
    await _propertyDao.deleteProperty(key);
  });

  @override
  Future<PropertyConfig?> getConfig(PropertyKey key) async {
    final entities = await _dao.getByKey(key);
    if (entities.isEmpty) {
      return null;
    }
    final storedList = entities.toStoredList();
    return PropertyConfigParser.parse(key, storedList, _descriptorMap);
  }
}
