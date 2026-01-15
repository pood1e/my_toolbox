import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../pomodoro_dao.dart';
import '../pomodoro_database.dart';
import '../pomodoro_tables.dart';
import 'pomodoro_dto.dart';
import 'sync_mappers.dart';

class PomodoroSyncHandler
    extends
        LwwSyncHandler<
          PomodoroDatabase,
          Pomodoros,
          PomodoroEntity,
          SimpleLwwSnapshot,
          PomodoroDto,
          SimpleLwwAck,
          PomodoroDao
        >
    implements
        CompositeSyncHandler<
          PomodoroDao,
          CommonSyncRequestPart<PomodoroDto>,
          CommonSyncResponsePart<SimpleLwwAck, PomodoroDto>
        > {
  @override
  PomodoroDto fromEntity(PomodoroEntity entity) {
    return entity.toDto();
  }

  @override
  SimpleLwwAck fromJsonACK(Map<String, dynamic> json) {
    return SimpleLwwAck.fromJson(json);
  }

  @override
  PomodoroDto fromJsonP(Map<String, dynamic> json) {
    return PomodoroDto.fromJson(json);
  }

  @override
  SimpleLwwSnapshot fromPayload(PomodoroDto payload) {
    return SimpleLwwSnapshot(id: payload.id, updatedAt: payload.updatedAt);
  }

  @override
  Insertable<PomodoroEntity> fromServerPayload(PomodoroDto payload) {
    return payload.toSyncCompanion();
  }

  @override
  Map<String, dynamic> payloadToJson(PomodoroDto payload) {
    return payload.toJson();
  }

  @override
  String get key => 'pomodoro';
}
