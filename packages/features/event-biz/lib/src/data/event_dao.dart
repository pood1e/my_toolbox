import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'event_database.dart';
import 'event_dto.dart';
import 'event_mapper.dart';
import 'event_table.dart';

part 'event_dao.g.dart';

@DriftAccessor(tables: [Events])
class EventDao extends DatabaseAccessor<EventDatabase>
    with
        _$EventDaoMixin,
        TableInfoMixin<Events, EventEntity>,
        SoftDeleteSyncDaoMixin<EventDatabase, Events, EventEntity>,
        SoftDeleteLwwDaoMixin<EventDatabase, Events, EventEntity>,
        PrimaryKeyDaoMixin<Events, EventEntity>,
        AckPatchSyncDaoMixin<
          EventDatabase,
          EventSnapshot,
          EventAck,
          Events,
          EventEntity
        >,
        DirtySelectSyncDaoMixin<EventDatabase, Events, EventEntity>,
        MaxCursorSyncDaoMixin<EventDatabase, Events, EventEntity>,
        LwwDaoSyncMixin<
          EventDatabase,
          Events,
          EventEntity,
          EventSnapshot,
          EventAck,
          EventDto
        >,
        SyncTransactionalDaoMixin<EventDatabase>,
        CommonDaoMixin<EventDatabase, Events, EventEntity> {
  EventDao(super.db);

  @override
  TableInfo<Events, EventEntity> get table => events;

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

  @override
  Insertable<EventEntity> toLwwComponion(EventDto payload) {
    return payload.toCompanion();
  }
}
