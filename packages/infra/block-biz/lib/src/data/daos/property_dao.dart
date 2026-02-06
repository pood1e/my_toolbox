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

  SimpleSelectStatement<$PropertiesTable, PropertyEntity> _selectProperties(
    Set<PropertyStorageKey> keys,
  ) {
    final query = select(properties);

    if (keys.isEmpty) {
      query.where((t) => const Constant(false));
      return query;
    }

    query.where(
      (t) => keys
          .map((key) => t.nodeId.equals(key.nodeId) & t.defId.equals(key.defId))
          .reduce((a, b) => a | b),
    );

    return query;
  }

  /// 标记一组节点为循环依赖错误
  Future<void> markAsCycleError(Set<PropertyKey> keys) async {
    if (keys.isEmpty) return;

    // 构建 where 语句
    final query = update(properties)
      ..where(
        (t) => keys
            .map((k) => t.nodeId.equals(k.nodeId) & t.defId.equals(k.defId))
            .reduce((a, b) => a | b),
      );

    await query.write(
      PropertiesCompanion(
        valueStatus: const Value(ValueStatus.error),
        errorType: const Value(ComputeError.cycle),
      ),
    );
  }

  Future<List<PropertyEntity>> getProperties(Set<PropertyStorageKey> keys) {
    return _selectProperties(keys).get();
  }

  Stream<List<PropertyEntity>> watchProperties(Set<PropertyStorageKey> keys) {
    return _selectProperties(keys).watch();
  }

  Stream<PropertyEntity> watchProperty(PropertyStorageKey key) {
    return _selectProperties({key}).watchSingle();
  }

  /// 递归标记脏状态（包含自身）
  Future<void> markTransitiveDirty(Set<PropertyKey> changedKeys) =>
      markDirtyRecursive(changedKeys, includeSelf: true);

  /// 通用递归标记逻辑
  Future<void> markDirtyRecursive(
    Set<PropertyKey> changedKeys, {
    required bool includeSelf,
  }) async {
    if (changedKeys.isEmpty) return;

    final buffer = StringBuffer();
    final args = <Object>[];

    int i = 0;
    for (final key in changedKeys) {
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
}

@riverpod
Future<PropertyDao> propertyDao(Ref ref) async {
  final db = await ref.watch(nodeDatabaseProvider.future);
  return PropertyDao(db);
}
