import 'package:drift/src/runtime/data_class.dart';
import 'package:framework_api/framework_api.dart';

import '../pomodoro_dao.dart';
import '../pomodoro_database.dart';
import '../pomodoro_tables.dart';
import 'pomodoro_dto.dart';
import 'sync_mappers.dart';

class PomodoroSessionSyncHandler
    extends
        LwwSyncHandler<
          PomodoroDatabase,
          PomodoroSessions,
          PomodoroSessionEntity,
          SimpleLwwSnapshot,
          PomodoroSessionDto,
          SimpleLwwAck,
          PomodoroSessionDao
        >
    implements
        CompositeSyncHandler<
          PomodoroSessionDao,
          CommonSyncRequestPart<PomodoroSessionDto>,
          CommonSyncResponsePart<SimpleLwwAck, PomodoroSessionDto>
        > {
  @override
  PomodoroSessionDto fromEntity(PomodoroSessionEntity entity) {
    return entity.toDto();
  }

  @override
  SimpleLwwAck fromJsonACK(Map<String, dynamic> json) {
    return SimpleLwwAck.fromJson(json);
  }

  @override
  PomodoroSessionDto fromJsonP(Map<String, dynamic> json) {
    return PomodoroSessionDto.fromJson(json);
  }

  @override
  SimpleLwwSnapshot fromPayload(PomodoroSessionDto payload) {
    return SimpleLwwSnapshot(id: payload.id, updatedAt: payload.updatedAt);
  }

  @override
  Insertable<PomodoroSessionEntity> fromServerPayload(
    PomodoroSessionDto payload,
  ) {
    return payload.toSyncCompanion();
  }

  @override
  Map<String, dynamic> payloadToJson(PomodoroSessionDto payload) {
    return payload.toJson();
  }

  @override
  String get key => 'session';
}
