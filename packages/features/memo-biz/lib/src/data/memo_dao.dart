import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'memo_database.dart';
import 'memo_dto.dart';
import 'memo_mapper.dart';
import 'memo_table.dart';

part 'memo_dao.g.dart';

@DriftAccessor(tables: [Memos])
class MemoDao extends DatabaseAccessor<MemoDatabase>
    with
        _$MemoDaoMixin,
        TableInfoMixin<Memos, Memo>,
        PrimaryKeyDaoMixin<Memos, Memo>,
        AckPatchSyncDaoMixin<MemoDatabase, MemoSnapshot, MemoAck, Memos, Memo>,
        DirtySelectSyncDaoMixin<MemoDatabase, Memos, Memo>,
        MaxCursorSyncDaoMixin<MemoDatabase, Memos, Memo>,
        CocDaoSyncMixin<
          MemoDatabase,
          Memos,
          Memo,
          MemoSnapshot,
          MemoAck,
          MemoPayload
        >,
        CommonDaoMixin<MemoDatabase, Memos, Memo>,
        SyncTransactionalDaoMixin<MemoDatabase> {
  MemoDao(super.attachedDatabase);

  @override
  TableInfo<Memos, Memo> get table => memos;

  @override
  Insertable<Memo> toCocCompanion(MemoPayload payload) {
    return payload.toCompanion();
  }
}

@riverpod
Future<MemoDao> memoDao(Ref ref) async {
  return MemoDao(await ref.watch(memoDatabaseProvider.future));
}
