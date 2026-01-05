import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'event_database.dart';
import 'event_entity.dart';
import 'event_mapper.dart';
import 'event_table.dart';

part 'event_dao.g.dart';

@DriftAccessor(tables: [Events])
class EventDao extends DatabaseAccessor<EventDatabase>
    with
        _$EventDaoMixin,
        LwwSyncDaoMixin<EventDatabase, Events, EventEntity>,
        LwwGcMixin<EventDatabase, Events, EventEntity> {
  EventDao(super.db);

  @override
  TableInfo<Events, EventEntity> get table => events;

  Future<int> updateIfExist(EventsCompanion companion) {
    return (update(events)..where(
          (t) =>
              t.id.equals(companion.id.value) &
              t.source.equals(companion.source.value),
        ))
        .write(companion);
  }

  Future<int> createIfNotExist(EventsCompanion companion) {
    return into(events).insert(companion, mode: InsertMode.insertOrIgnore);
  }

  /// 根据时间范围查询事件
  /// 自动过滤掉已删除的数据
  Stream<List<EventEntity>> watchByRange(int startTime, int endTime) {
    return (select(events)
          ..where((t) => t.timestamp.isBetweenValues(startTime, endTime))
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 根据 ID 和 Source 进行软删除
  /// 返回受影响的行数
  Future<int> softDeleteBySourceAndId(
    String id,
    String source,
    int deletedTime,
  ) {
    return (update(events)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.source.equals(source)))
        .write(
          EventsCompanion(
            deletedAt: Value(deletedTime),
            updatedAt: Value(deletedTime),
            isDirty: const Value(true), // 标记为脏数据，以便 SyncDelegate 同步删除操作
          ),
        );
  }

  @override
  UpdateCompanion<EventEntity> toCompanion(EventEntity e) {
    return e.toCompanion();
  }

  @override
  Expression<bool> whereId(Events t, List<dynamic> primaryId) {
    return t.id.equals(primaryId[0]);
  }
}
