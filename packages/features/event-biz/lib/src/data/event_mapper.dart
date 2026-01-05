import 'package:drift/drift.dart';
import 'package:event_api/event_api.dart';

import 'event_database.dart';
import 'event_dto.dart';
import 'event_entity.dart';

extension EventEntityToDto on EventEntity {
  EventDto toDto() {
    return EventDto(
      id: id,
      name: name,
      timestamp: timestamp,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension EventDtoToEntity on EventDto {
  EventEntity toEntity({bool isDirty = false}) {
    return EventEntity(
      id: id,
      name: name,
      timestamp: timestamp,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
      serverUpdatedAt: serverUpdatedAt,
      isDirty: isDirty,
    );
  }
}

extension EventEntityToCompanion on EventEntity {
  EventsCompanion toCompanion() {
    return EventsCompanion(
      id: Value(id),
      name: Value(name),
      timestamp: Value(timestamp),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      deletedAt: Value(deletedAt),
    );
  }
}

extension EventEntityToDomain on EventEntity {
  Event toDomain() {
    return Event(id: id, name: name, timestamp: timestamp, source: source);
  }
}
