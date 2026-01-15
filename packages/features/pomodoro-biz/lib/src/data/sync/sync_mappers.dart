import 'package:drift/drift.dart';

import '../pomodoro_database.dart';
import 'pomodoro_dto.dart';

extension PomodoroDtoToCompanion on PomodoroDto {
  PomodorosCompanion toSyncCompanion() {
    return PomodorosCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      startAt: Value(startAt),
      endAt: Value(endAt),
      type: Value(type),

      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(false),
    );
  }
}

extension PomodoroEntityToDto on PomodoroEntity {
  PomodoroDto toDto() {
    return PomodoroDto(
      id: id,
      sessionId: sessionId,
      startAt: startAt,
      endAt: endAt,
      type: type,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension PomodoroSessionDtoToCompanion on PomodoroSessionDto {
  PomodoroSessionsCompanion toSyncCompanion() {
    return PomodoroSessionsCompanion(
      id: Value(id),
      name: Value(name),
      note: Value(note),

      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(false),
    );
  }
}

extension PomodoroSessionEntityToDto on PomodoroSessionEntity {
  PomodoroSessionDto toDto() {
    return PomodoroSessionDto(
      id: id,
      name: name,
      note: note,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}
