import 'package:drift/drift.dart';

import '../pomodoro_domain.dart';
import 'pomodoro_dao.dart';
import 'pomodoro_database.dart';
import 'pomodoro_mappers.dart';
import 'pomodoro_repository.dart';

class PomodoroRepositoryImpl implements PomodoroRepository {
  final PomodoroDao _pomodoroDao;
  final PomodoroSessionDao _sessionDao;

  PomodoroRepositoryImpl({
    required PomodoroDao pomodoroDao,
    required PomodoroSessionDao sessionDao,
  }) : _pomodoroDao = pomodoroDao,
       _sessionDao = sessionDao;

  @override
  Future<void> savePomodoro(Pomodoro pomodoro, int serverTime) async {
    await _pomodoroDao.createIfNotExist(
      pomodoro.toInsertEntity(updatedAt: serverTime),
    );
  }

  @override
  Future<void> saveSession(PomodoroSession session, int serverTime) async {
    await _sessionDao.createIfNotExist(
      session.toInsertEntity(updatedAt: serverTime),
    );
  }

  @override
  Future<void> updatePomodoroEndTime(
    String id,
    int newEndAt,
    int serverTime,
  ) async {
    await _pomodoroDao.updateIfExist(
      PomodorosCompanion(
        id: Value(id),
        endAt: Value(newEndAt),
        isDirty: Value(true),
        updatedAt: Value(serverTime),
      ),
    );
  }

  @override
  Future<void> updateSession(
    String id,
    String name,
    String? note,
    int serverTime,
  ) async {
    await _sessionDao.updateIfExist(
      PomodoroSessionsCompanion(
        id: Value(id),
        name: Value(name),
        note: Value(note),
        updatedAt: Value(serverTime),
        isDirty: Value(true),
      ),
    );
  }

  Pomodoro _mapRowToDomain(TypedResult row) {
    final pomodoroEntity = row.readTable(_pomodoroDao.pomodoros);
    final sessionEntity = row.readTable(_sessionDao.pomodoroSessions);

    return Pomodoro(
      id: pomodoroEntity.id,
      // 组装 Session 对象
      session: PomodoroSession(
        id: sessionEntity.id,
        name: sessionEntity.name,
        note: sessionEntity.note,
      ),
      startAt: pomodoroEntity.startAt,
      endAt: pomodoroEntity.endAt,
      type: pomodoroEntity.type,
    );
  }

  @override
  Stream<Pomodoro?> watchActivePomodoro(int tick) {
    return _pomodoroDao.watchProcessing(tick).map((row) {
      if (row == null) return null;
      return _mapRowToDomain(row);
    });
  }

  @override
  Stream<List<Pomodoro>> watchHistory(int tick) {
    return _pomodoroDao.watchHistory(tick).map((rows) {
      return rows.map((row) => _mapRowToDomain(row)).toList();
    });
  }

  @override
  Future<Pomodoro?> getPomodoroById(String id) async {
    final result = await _pomodoroDao.getPomodoroById(id);
    if (result == null) {
      return null;
    }
    return _mapRowToDomain(result);
  }
}
