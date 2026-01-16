import 'package:drift/drift.dart';

import '../pomodoro_domain.dart';
import 'pomodoro_database.dart';

extension PomodoroDomainToEntity on Pomodoro {
  Insertable<PomodoroEntity> toInsertEntity({required int updatedAt}) {
    return PomodorosCompanion.insert(
      updatedAt: updatedAt,
      id: id,
      sessionId: session.id,
      startAt: startAt,
      endAt: endAt,
      type: type,
      isDirty: Value(true),
    );
  }
}

extension PomodoroSessionDomainToEntity on PomodoroSession {
  Insertable<PomodoroSessionEntity> toInsertEntity({required int updatedAt}) {
    return PomodoroSessionsCompanion.insert(
      updatedAt: updatedAt,
      id: id,
      name: name,
      note: Value(note),
      manualClosed: Value(manualClosed),
      isDirty: Value(true),
    );
  }
}
