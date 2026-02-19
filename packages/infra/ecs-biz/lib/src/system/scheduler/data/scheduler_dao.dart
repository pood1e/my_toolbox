import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../relation/data/property_relations.dart';
import '../../storage/ecs_database.dart';
import '../../value/data/property_val.dart';
import '../../value/value_service.dart';

part 'scheduler_dao.g.dart';

@DriftAccessor(tables: [PropertyVals, PropertyRelations])
class SchedulerDao extends DatabaseAccessor<EcsDatabase>
    with _$SchedulerDaoMixin {
  SchedulerDao(super.attachedDatabase);

  Stream<bool> watchHasDirty() {
    final query = selectOnly(propertyVals)
      ..addColumns([const Constant(1)])
      ..where(propertyVals.status.equalsValue(ValueStatus.dirty))
      ..limit(1);

    return query.watch().map((rows) => rows.isNotEmpty);
  }

  Future<List<PropertyId>> getDirties() async {
    final query = selectOnly(propertyVals)
      ..addColumns([propertyVals.nodeId, propertyVals.metaId])
      ..where(propertyVals.status.equalsValue(ValueStatus.dirty));
    final result = await query.get();
    return result
        .map(
          (row) => PropertyId(
            nodeId: row.read(propertyVals.nodeId)!,
            metaId: row.read(propertyVals.metaId)!,
          ),
        )
        .toList();
  }

  Future<List<QueryRow>> getDirtyDependencyEdges(
    List<PropertyId> dirties,
  ) async {
    if (dirties.isEmpty) return [];

    return transaction(() async {
      // 1. 创建临时表 (仅当前连接有效，内存表速度快)
      await customStatement(
        'CREATE TEMPORARY TABLE IF NOT EXISTS tmp_dirty_properties (node_id TEXT, meta_id TEXT)',
      );
      // 防御性清理
      await customStatement('DELETE FROM tmp_dirty_properties');

      // 2. 批量插入脏节点
      await batch((batch) {
        for (final dirty in dirties) {
          batch.customStatement(
            'INSERT INTO tmp_dirty_properties (node_id, meta_id) VALUES (?, ?)',
            [dirty.nodeId, dirty.metaId],
          );
        }
      });

      // 3. 核心查询：找出内部依赖边
      // 逻辑：Source(node_id) 和 Target(target_node_id) 都在 tmp 表中
      final result = await customSelect(
        '''
      SELECT 
        rel.src_node, 
        rel.src_meta,
        rel.dst_node, 
        rel.dst_meta
      FROM property_relations rel
      -- 1. 筛选 Source (依赖者) 必须是脏的
      INNER JOIN tmp_dirty_properties src_tmp 
        ON rel.src_node = src_tmp.node_id AND rel.src_meta = src_tmp.meta_id
      -- 2. 筛选 Target (被依赖者) 必须是脏的
      INNER JOIN tmp_dirty_properties dst_tmp 
        ON rel.dst_node = dst_tmp.node_id AND rel.dst_meta = dst_tmp.meta_id
      WHERE rel.affect_value = 1
      ''',
        readsFrom: {propertyRelations},
      ).get();

      // 4. 清理临时表 (可选，SQLite连接关闭会自动清，但手动清是个好习惯)
      await customStatement('DROP TABLE tmp_dirty_properties');

      // 5. 返回结果
      return result;
    });
  }
}
