import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'data/memo_dao.dart';
import 'data/memo_database.dart';
import 'data/memo_mapper.dart';
import 'memo_domain.dart';

part 'memo_repository.g.dart';

abstract class MemoRepository {
  Stream<List<MemoDomain>> watchMemos({bool isArchived = false});

  Future<MemoDomain?> getMemo(String id);

  Future<void> saveMemo({
    required String id,
    required String content,
    required String contentHash,
    required int now,
  });

  Future<void> toggleArchive(String id, bool isArchived, int now);

  Future<void> deleteMemo(String id, int now);
}

class MemoRepositoryImpl implements MemoRepository {
  final MemoDao _dao;

  MemoRepositoryImpl(this._dao);

  @override
  Stream<List<MemoDomain>> watchMemos({bool isArchived = false}) {
    return (_dao.select(_dao.memos)
          ..where((t) {
            return t.deletedAt.isNull() & t.isArchived.equals(isArchived);
          })
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((entities) => entities.map((e) => e.toDomain()).toList());
  }

  @override
  Future<MemoDomain?> getMemo(String id) async {
    final entity = await (_dao.select(
      _dao.memos,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return entity?.toDomain();
  }

  @override
  Future<void> deleteMemo(String id, int now) async {
    await _dao.softDelete([id], now);
  }

  @override
  Future<void> toggleArchive(String id, bool isArchived, int now) async {
    await _dao.setArchived(id, isArchived, now);
  }

  @override
  Future<void> saveMemo({
    required String id,
    required String content,
    required String contentHash,
    required int now,
  }) async {
    await _dao.saveContent(
      id: id,
      content: content,
      hash: contentHash,
      now: now,
    );
  }
}

@riverpod
Future<MemoRepository> memoRepository(Ref ref) async {
  final dao = await ref.watch(memoDaoProvider.future);
  ref.watch(memoChangesListenerProvider);
  return MemoRepositoryImpl(dao);
}

@riverpod
Future<void> memoChangesListener(Ref ref) async {
  final db = await ref.watch(memoDatabaseProvider.future);

  final sub = db.tableUpdates(TableUpdateQuery.onTable(db.memos)).listen((
    updates,
  ) async {
    if (await ref.read(autoSyncEnabledProvider.future)) {
      final autoSyncService = await ref.watch(autoSyncServiceProvider.future);
      autoSyncService.markSync('memo');
    }
  });

  ref.onDispose(() {
    sub.cancel();
  });
}
