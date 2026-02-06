import 'package:app_core/di.dart';
import 'package:drift/drift.dart';

import '../../domain/property.dart';
import '../../domain/stored_value.dart';
import '../node_database.dart';
import '../tables/properties.dart';
import '../tables/property_config.dart';

part 'complex_compute_dao.g.dart';

@DriftAccessor(tables: [Properties, PropertyAtomConfigs])
class ComplexComputeDao extends DatabaseAccessor<NodeDatabase>
    with _$ComplexComputeDaoMixin {
  ComplexComputeDao(super.attachedDatabase);

  /// 通用递归标记逻辑
  Future<void> markDirtyRecursive({
    required Set<PropertyKey> rootKeys,
    bool includeSelf = true,
  }) async {
    if (rootKeys.isEmpty) return;

    final buffer = StringBuffer();
    final args = <Object>[];

    int i = 0;
    for (final key in rootKeys) {
      if (i > 0) buffer.write(',');
      // 这里的 0 是初始深度
      buffer.write('(?${i * 2 + 1}, ?${i * 2 + 2}, 0)');
      args.add(key.nodeId);
      args.add(key.defId);
      i++;
    }

    // 根据 includeSelf 决定过滤条件
    // includeSelf = true  -> depth >= 0 (包含初始节点)
    // includeSelf = false -> depth > 0  (排除初始节点)
    final depthCondition = includeSelf ? 'depth >= 0' : 'depth > 0';

    final sql =
        '''
      WITH RECURSIVE downstream(node_id, def_id, depth) AS (
        -- Base Case: 注入参数，深度设为 0
        VALUES ${buffer.toString()}
        
        UNION
        
        -- Recursive Step: 查找引用者，深度 + 1
        SELECT c.node_id, c.def_id, d.depth + 1
        FROM property_atom_configs c
        JOIN downstream d ON c.target_node_id = d.node_id AND c.target_def_id = d.def_id 
        WHERE c.affect_value = 1
      )
      -- 核心修改：尝试插入，如果冲突则更新
      INSERT INTO properties (node_id, def_id, value_status, error_type)
      SELECT node_id, def_id, ${ValueStatus.dirty.index}, NULL
      FROM downstream 
      WHERE $depthCondition
      ON CONFLICT(node_id, def_id) DO UPDATE SET
          value_status = excluded.value_status,
          error_type = NULL;
    ''';
    await customStatement(sql, args);
    markTablesUpdated({properties});
  }

  /// 通用错误递归标记
  Future<void> markErrorRecursive({
    required Set<PropertyKey> rootKeys,
    required ValueError rootError,
  }) async {
    if (rootKeys.isEmpty) return;

    final buffer = StringBuffer();
    final args = <Object>[];

    int i = 0;
    for (final key in rootKeys) {
      if (i > 0) buffer.write(',');
      buffer.write('(?${i * 2 + 1}, ?${i * 2 + 2}, 0)');
      args.add(key.nodeId);
      args.add(key.defId);
      i++;
    }

    final refErrorIndex = ValueError.referenceInvalid.index;
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
          val_bool = NULL,
          val_int = NULL,
          val_real = NULL,
          val_text = NULL,
          val_json = NULL
      FROM downstream d
      WHERE properties.node_id = d.node_id 
        AND properties.def_id = d.def_id
        AND (
          d.depth = 0  
          OR
          properties.value_status != $errorStatusIndex
        );
    ''';

    await customStatement(sql, args);
    markTablesUpdated({properties});
  }

  /// 获取局部依赖图
  /// 使用临时表方式
  Future<List<QueryRow>> getDirtyDependencyEdges(
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
      return result;
    });
  }

  Stream<bool> watchHasDirty() {
    final query = selectOnly(properties)
      ..addColumns([const Constant(1)]) // 我们不关心具体列，只关心有没有行
      ..where(properties.valueStatus.equals(ValueStatus.dirty.index))
      ..limit(1); // 只要找到一条就返回，性能最高

    return query.watch().map((rows) => rows.isNotEmpty);
  }

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
}

@riverpod
Future<ComplexComputeDao> complexComputeDao(Ref ref) async {
  final db = await ref.watch(nodeDatabaseProvider.future);
  return ComplexComputeDao(db);
}
