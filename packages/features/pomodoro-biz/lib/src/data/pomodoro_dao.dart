// ==========================================================
// 1. PomodoroSessionDao
// 负责会话表的纯 CRUD 操作
// ==========================================================
import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'pomodoro_database.dart';
import 'pomodoro_tables.dart';
import 'sync/pomodoro_dto.dart';
import 'sync/sync_mappers.dart';

part 'pomodoro_dao.g.dart';

@DriftAccessor(tables: [PomodoroSessions])
class PomodoroSessionDao extends DatabaseAccessor<PomodoroDatabase>
    with
        _$PomodoroSessionDaoMixin,
        TableInfoMixin<PomodoroSessions, PomodoroSessionEntity>,
        SoftDeleteSyncDaoMixin<
          PomodoroDatabase,
          PomodoroSessions,
          PomodoroSessionEntity
        >,
        SoftDeleteLwwDaoMixin<
          PomodoroDatabase,
          PomodoroSessions,
          PomodoroSessionEntity
        >,
        PrimaryKeyDaoMixin<PomodoroSessions, PomodoroSessionEntity>,
        AckPatchSyncDaoMixin<
          PomodoroDatabase,
          SimpleLwwSnapshot,
          SimpleLwwAck,
          PomodoroSessions,
          PomodoroSessionEntity
        >,
        DirtySelectSyncDaoMixin<
          PomodoroDatabase,
          PomodoroSessions,
          PomodoroSessionEntity
        >,
        MaxCursorSyncDaoMixin<
          PomodoroDatabase,
          PomodoroSessions,
          PomodoroSessionEntity
        >,
        LwwDaoSyncMixin<
          PomodoroDatabase,
          PomodoroSessions,
          PomodoroSessionEntity,
          SimpleLwwSnapshot,
          SimpleLwwAck,
          PomodoroSessionDto
        >,
        SyncTransactionalDaoMixin<PomodoroDatabase>,
        CommonDaoMixin<
          PomodoroDatabase,
          PomodoroSessions,
          PomodoroSessionEntity
        > {
  PomodoroSessionDao(super.db);

  @override
  TableInfo<PomodoroSessions, PomodoroSessionEntity> get table =>
      pomodoroSessions;

  @override
  Insertable<PomodoroSessionEntity> toLwwComponion(PomodoroSessionDto payload) {
    return payload.toSyncCompanion();
  }
}

@DriftAccessor(tables: [Pomodoros, PomodoroSessionDao])
class PomodoroDao extends DatabaseAccessor<PomodoroDatabase>
    with
        _$PomodoroDaoMixin,
        TableInfoMixin<Pomodoros, PomodoroEntity>,
        SoftDeleteSyncDaoMixin<PomodoroDatabase, Pomodoros, PomodoroEntity>,
        SoftDeleteLwwDaoMixin<PomodoroDatabase, Pomodoros, PomodoroEntity>,
        PrimaryKeyDaoMixin<Pomodoros, PomodoroEntity>,
        AckPatchSyncDaoMixin<
          PomodoroDatabase,
          SimpleLwwSnapshot,
          SimpleLwwAck,
          Pomodoros,
          PomodoroEntity
        >,
        DirtySelectSyncDaoMixin<PomodoroDatabase, Pomodoros, PomodoroEntity>,
        MaxCursorSyncDaoMixin<PomodoroDatabase, Pomodoros, PomodoroEntity>,
        LwwDaoSyncMixin<
          PomodoroDatabase,
          Pomodoros,
          PomodoroEntity,
          SimpleLwwSnapshot,
          SimpleLwwAck,
          PomodoroDto
        >,
        SyncTransactionalDaoMixin<PomodoroDatabase>,
        CommonDaoMixin<PomodoroDatabase, Pomodoros, PomodoroEntity> {
  PomodoroDao(super.attachedDatabase);

  @override
  TableInfo<Pomodoros, PomodoroEntity> get table => pomodoros;

  @override
  Insertable<PomodoroEntity> toLwwComponion(PomodoroDto payload) {
    return payload.toSyncCompanion();
  }

  JoinedSelectStatement _selectPomodoro() {
    return select(pomodoros).join([
      innerJoin(
        pomodoroSessions,
        pomodoroSessions.id.equalsExp(pomodoros.sessionId),
      ),
    ])..orderBy([OrderingTerm.desc(pomodoros.startAt)]);
  }

  Stream<TypedResult?> watchProcessing(int tick) async* {
    final query = _selectPomodoro()
      ..where(
        pomodoros.endAt.isBiggerThanValue(tick) & pomodoros.deletedAt.isNull(),
      )
      ..limit(1);
    yield* query.watchSingleOrNull();
  }

  Stream<List<TypedResult>> watchHistory(int tick) async* {
    final query = _selectPomodoro()
      ..where(
        pomodoros.endAt.isSmallerThanValue(tick) & pomodoros.deletedAt.isNull(),
      );
    yield* query.watch();
  }

  Future<TypedResult?> getPomodoroById(String id) async {
    final query = _selectPomodoro()
      ..where(pomodoros.id.equals(id) & pomodoros.deletedAt.isNull());
    return query.getSingle();
  }
}

@riverpod
Future<PomodoroDao> pomodoroDao(Ref ref) async {
  return PomodoroDao(await ref.watch(pomodoroDatabaseProvider.future));
}

@riverpod
Future<PomodoroSessionDao> pomodoroSessionDao(Ref ref) async {
  return PomodoroSessionDao(await ref.watch(pomodoroDatabaseProvider.future));
}
