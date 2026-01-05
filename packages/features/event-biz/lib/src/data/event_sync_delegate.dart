import 'package:framework_api/framework_api.dart';

import 'event_database.dart';
import 'event_dto.dart';
import 'event_entity.dart';
import 'event_mapper.dart';
import 'event_table.dart';

class EventSyncDelegate
    extends
        LwwSoftDeleteSyncDelegateBase<
          EventDatabase,
          Events,
          EventEntity,
          EventDto,
          EventAck
        > {
  EventSyncDelegate({required super.daoUse, required super.dio});

  @override
  String get resourceId => 'event';

  @override
  EventAck ackFromJson(Map<String, dynamic> json) {
    return EventAck.fromJson(json);
  }

  @override
  String get apiPath => '/event/sync';

  @override
  EventDto dtoFromJson(Map<String, dynamic> json) {
    return EventDto.fromJson(json);
  }

  @override
  EventDto toDto(EventEntity entity) {
    return entity.toDto();
  }

  @override
  EventEntity toEntity(EventDto dto) {
    return dto.toEntity(isDirty: false);
  }

  @override
  Map<String, dynamic> dtoToJson(EventDto dto) {
    return dto.toJson();
  }
}
