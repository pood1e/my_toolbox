import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../../domain/property.dart';
import '../node_database.dart';
import '../tables/properties.dart';
import '../tables/property_config.dart';
import 'property_atom_config_dao.dart';
import 'property_dao.dart';

part 'compute_property_dao.g.dart';

/// todo: 转换逻辑移出
@DriftAccessor(tables: [Properties, PropertyAtomConfigs])
class ComputePropertyDao extends DatabaseAccessor<NodeDatabase>
    with _$ComputePropertyDaoMixin {
  final PropertyAtomConfigDao _configDao;
  final PropertyDao _propertyDao;

  ComputePropertyDao(
    super.attachedDatabase, {
    required PropertyAtomConfigDao configDao,
    required PropertyDao propertyDao,
  }) : _configDao = configDao,
       _propertyDao = propertyDao;

  Future<List<DependencyEdge>> getDirtyDependencyEdges(
    List<PropertyKey> dirties,
  ) async {
    if (dirties.isEmpty) return [];

    return transaction(() async {
      // 1. 创建临时表 (仅当前连接有效，内存表速度快)
      await customStatement(
        'CREATE TEMPORARY TABLE IF NOT EXISTS tmp_dirty_nodes (id TEXT, def TEXT)',
      );
      // 防御性清理
      await customStatement('DELETE FROM tmp_dirty_nodes');

      // 2. 批量插入脏节点
      await batch((batch) {
        for (final dirty in dirties) {
          batch.customStatement(
            'INSERT INTO tmp_dirty_nodes (id, def) VALUES (?, ?)',
            [dirty.nodeId, dirty.defId],
          );
        }
      });

      // 3. 核心查询：找出内部依赖边
      // 逻辑：Source(node_id) 和 Target(target_node_id) 都在 tmp 表中
      final result = await customSelect(
        '''
      SELECT 
        cfg.node_id, 
        cfg.def_id,
        cfg.target_node_id, 
        cfg.target_def_id
      FROM property_atom_configs cfg
      -- 1. 筛选 Source (依赖者) 必须是脏的
      INNER JOIN tmp_dirty_nodes src_tmp 
        ON cfg.node_id = src_tmp.id AND cfg.def_id = src_tmp.def
      -- 2. 筛选 Target (被依赖者) 必须是脏的
      INNER JOIN tmp_dirty_nodes tgt_tmp 
        ON cfg.target_node_id = tgt_tmp.id AND cfg.target_def_id = tgt_tmp.def
      WHERE cfg.affect_value = 1
      ''',
        readsFrom: {propertyAtomConfigs},
      ).get();

      // 4. 清理临时表 (可选，SQLite连接关闭会自动清，但手动清是个好习惯)
      await customStatement('DROP TABLE tmp_dirty_nodes');

      // 5. 返回结果
      return result.map((row) {
        return DependencyEdge(
          source: PropertyKey(
            nodeId: row.read('node_id'),
            defId: row.read('def_id'),
          ),
          target: PropertyKey(
            nodeId: row.read('target_node_id'),
            defId: row.read('target_def_id'),
          ),
        );
      }).toList();
    });
  }

  Stream<bool> watchHasDirty() {
    final query = selectOnly(properties)
      ..addColumns([const Constant(1)]) // 我们不关心具体列，只关心有没有行
      ..where(properties.valueStatus.equals(ValueStatus.dirty.index))
      ..limit(1); // 只要找到一条就返回，性能最高

    return query.watch().map((rows) => rows.isNotEmpty);
  }

  // 提供给 Worker 内部循环使用的主动拉取方法
  Future<List<PropertyKey>> getDirtyProperties() async {
    final query = selectOnly(properties)
      ..addColumns([properties.nodeId, properties.defId])
      ..where(properties.valueStatus.equalsValue(ValueStatus.dirty));
    final result = await query.get();
    return result
        .map(
          (row) => PropertyKey(
            nodeId: row.read(properties.nodeId)!,
            defId: row.read(properties.defId)!,
          ),
        )
        .toList();
  }

  Future<void> markPropertiesError(
    Map<PropertyKey, ComputeError> errors,
  ) async {
    if (errors.isEmpty) return;

    await batch((batch) {
      for (final entry in errors.entries) {
        final key = entry.key;
        final error = entry.value;

        batch.update(
          properties,
          PropertiesCompanion(
            // 将 ComputeError 枚举转为 int 存储
            errorType: Value(error),
            // 变脏通常意味着数值状态不可信，但这里我们只标记错误类型
            // 如果需要同时把 valueStatus 改为 error，也可以在这里加
          ),
          where: (t) => t.nodeId.equals(key.nodeId) & t.defId.equals(key.defId),
        );
      }
    });
  }

  /// 递归标记下游脏状态（**不**包含自身）
  Future<void> markOnlyDownstreamDirty(Set<PropertyKey> changedKeys) =>
      _propertyDao.markDirtyRecursive(changedKeys, includeSelf: false);

  /// 场景1：自身配置错误 (ConfigError)，导致下游引用失效 (RefError)
  Future<void> markAsConfigError(Set<PropertyKey> keys) =>
      _propagateErrorRecursive(keys, rootError: ComputeError.config);

  /// 场景2：自身引用失效 (RefError)，导致下游引用失效 (RefError)
  /// 通常用于中间节点，或者引用的外部变量被删除了
  Future<void> markAsRefError(Set<PropertyKey> keys) =>
      _propagateErrorRecursive(keys, rootError: ComputeError.ref);

  Future<void> _propagateErrorRecursive(
    Set<PropertyKey> changedKeys, {
    required ComputeError rootError,
  }) async {
    if (changedKeys.isEmpty) return;

    final buffer = StringBuffer();
    final args = <Object>[];

    int i = 0;
    for (final key in changedKeys) {
      if (i > 0) buffer.write(',');
      buffer.write('(?${i * 2 + 1}, ?${i * 2 + 2}, 0)');
      args.add(key.nodeId);
      args.add(key.defId);
      i++;
    }

    final refErrorIndex = ComputeError.ref.index;
    final rootErrorIndex = rootError.index;
    final errorStatusIndex = ValueStatus.error.index;

    // SQL 逻辑变化：
    // 在 WHERE 子句中增加了状态检查
    final sql =
        '''
      WITH RECURSIVE downstream(node_id, def_id, depth) AS (
        VALUES ${buffer.toString()}
        UNION
        SELECT c.node_id, c.def_id, d.depth + 1
        FROM property_atom_configs c
        JOIN downstream d ON c.target_node_id = d.node_id AND c.target_def_id = d.def_id 
        WHERE c.affect_value = 1
      )
      UPDATE properties 
      SET value_status = $errorStatusIndex,
          error_type = CASE 
              WHEN d.depth = 0 THEN $rootErrorIndex 
              ELSE $refErrorIndex 
          END
      FROM downstream d
      WHERE properties.node_id = d.node_id 
        AND properties.def_id = d.def_id
        -- 【核心修改】过滤逻辑
        AND (
          -- 1. 根节点(触发源)总是更新 (哪怕它之前是其他错误, 现在被显式标记了)
          d.depth = 0  
          OR
          -- 2. 下游节点：只有当前不是 Error 时才被感染 (即只感染 Normal 或 Dirty)
          properties.value_status != $errorStatusIndex
        );
    ''';

    await customStatement(sql, args);
    markTablesUpdated({properties});
  }

  Future<void> saveProperty(PropertiesCompanion companion) async {
    await into(properties).insertOnConflictUpdate(companion);
  }

  Future<void> deleteProperty(PropertyKey key) async {
    final query = delete(properties)
      ..where((t) => t.nodeId.equals(key.nodeId) & t.defId.equals(key.defId));
    await query.go();
  }

  Future<List<PropertyAtomConfigEntity>> getConfig(PropertyKey key) {
    return _configDao.getByKey(key);
  }
}

class DependencyEdge {
  final PropertyKey source; // 依赖者 (Effect / result) -> 需要等待
  final PropertyKey target; // 被依赖者 (Cause / dependency) -> 需要先算

  DependencyEdge({required this.source, required this.target});
}

@riverpod
Future<ComputePropertyDao> computePropertyDao(Ref ref) async {
  final propertyDao = await ref.watch(propertyDaoProvider.future);
  final configDao = await ref.watch(propertyAtomConfigDaoProvider.future);
  final db = await ref.watch(nodeDatabaseProvider.future);
  return ComputePropertyDao(db, configDao: configDao, propertyDao: propertyDao);
}
