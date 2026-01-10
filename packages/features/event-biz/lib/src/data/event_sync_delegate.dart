import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'event_dao.dart';
import 'event_database.dart';
import 'event_dto.dart';
import 'event_mapper.dart';
import 'event_table.dart';

class EventSyncHandler
    extends
        LwwSyncHandler<
          EventDatabase,
          Events,
          EventEntity,
          EventSnapshot,
          EventDto,
          EventAck,
          EventDao
        > {
  @override
  EventDto fromEntity(EventEntity entity) {
    return entity.toDto();
  }

  @override
  EventAck fromJsonACK(Map<String, dynamic> json) {
    return EventAck.fromJson(json);
  }

  @override
  EventDto fromJsonP(Map<String, dynamic> json) {
    return EventDto.fromJson(json);
  }

  @override
  EventSnapshot fromPayload(EventDto payload) {
    return EventSnapshot(
      id: payload.id,
      source: payload.source,
      updatedAt: payload.updatedAt,
    );
  }

  @override
  Insertable<EventEntity> fromServerPayload(EventDto payload) {
    return payload.toCompanion();
  }

  @override
  Map<String, dynamic> payloadToJson(EventDto payload) {
    return payload.toJson();
  }
}

class EventSyncDelegate
    extends
        StandardSingleSyncDelegate<
          EventDao,
          EventDto,
          EventAck,
          CommonSyncRequestPart<EventDto>,
          CommonSyncResponsePart<EventAck, EventDto>
        > {
  EventSyncDelegate({required super.dio, required super.resourceUse})
    : super(handler: EventSyncHandler());

  @override
  String get resourceId => 'event';
}
