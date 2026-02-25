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
  ) {
    final query = select(propertyVals);
    if (ids.isEmpty) {
      // 如果 ID 为空，直接加上一个绝对为 false 的条件，让查询返回空结果而不崩溃
      query.where((t) => const Constant(false));
      return query;
    }

    query.where(
      (t) => ids
          .map((id) => t.metaId.equals(id.metaId) & t.nodeId.equals(id.nodeId))
          .reduce((a, b) => a | b),
    );
    return query;
  }

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

  /// 过滤出当前状态为 valid (有效) 的属性 ID 集合
  Future<Set<PropertyId>> filterValueValid(Set<PropertyId> propertyIds) async {
    if (propertyIds.isEmpty) return {};

    final Set<PropertyId> validIds = {};
    final idsList = propertyIds.toList();

    // 分批处理，防止传入巨量 ID 时触发 SQLite 最大表达式深度限制崩溃
    const int batchSize = 100;

    for (var i = 0; i < idsList.length; i += batchSize) {
      final end = (i + batchSize < idsList.length)
          ? i + batchSize
          : idsList.length;
      final batch = idsList.sublist(i, end);

      // 性能优化：仅查询所需的 nodeId 和 metaId 字段，不拉取具体的 value 数据
      final query = selectOnly(propertyVals)
        ..addColumns([propertyVals.nodeId, propertyVals.metaId])
        // 假设你的枚举中表示有效的值是 ValueStatus.valid
        // 如果你的命名不同（例如 ValueStatus.success），请自行替换下面的枚举值
        ..where(propertyVals.status.equalsValue(ValueStatus.normal))
        ..where(
          batch
              .map(
                (id) =>
                    propertyVals.nodeId.equals(id.nodeId) &
                    propertyVals.metaId.equals(id.metaId),
              )
              .reduce((a, b) => a | b),
        );

      final rows = await query.get();

      validIds.addAll(
        rows.map(
          (row) => PropertyId(
            nodeId: row.read(propertyVals.nodeId)!,
            metaId: row.read(propertyVals.metaId)!,
          ),
        ),
      );
    }

    return validIds;
  }
}

@riverpod
Future<ValueDao> valueDao(Ref ref) async {
  final db = await ref.watch(ecsDatabaseProvider.future);
  return ValueDao(db);
}
