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
        SoftDeleteSyncDaoMixin<MemoDatabase, Memos, Memo>,
        SoftDeleteCocDaoMixin<MemoDatabase, Memos, Memo>,
        SyncTransactionalDaoMixin<MemoDatabase> {
  MemoDao(super.attachedDatabase);

  @override
  TableInfo<Memos, Memo> get table => memos;

  @override
  Insertable<Memo> toCocCompanion(MemoPayload payload) {
    return payload.toCompanion();
  }

  Future<void> saveContent({
    required String id,
    required String content,
    required String hash,
    required int now,
  }) async {
    await transaction(() async {
      // 1. [Read-Before-Write] 查询现有数据
      final existing = await (select(memos)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

      // 2. [Check & Branch]
      if (existing != null) {
        // 场景 A: 数据已被软删除
        // 需求是"不复活"，通常意味着也不应该更新它的内容，直接忽略本次操作
        if (existing.deletedAt != null) {
          return;
        }

        // 场景 B: 数据正常，但内容没变 (Hash 一致)
        if (existing.contentHash == hash) {
          return;
        }

        // 场景 C: 数据正常，内容变了 -> 执行 UPDATE
        // 只更新必要字段，不触碰 createdAt 和 isArchived
        await (update(memos)..where((t) => t.id.equals(id))).write(
          MemosCompanion(
            content: Value(content),
            contentHash: Value(hash),
            updatedAt: Value(now),
            isDirty: const Value(true),
            // 注意：这里完全不传 deletedAt，保持它是 null
          ),
        );
      } else {
        // 3. [Insert] 数据不存在 -> 执行 INSERT
        await into(memos).insert(
          MemosCompanion(
            id: Value(id),
            content: Value(content),
            contentHash: Value(hash),
            createdAt: Value(now),
            updatedAt: Value(now),
            isArchived: const Value(false),
            isDirty: const Value(true),
            deletedAt: const Value(null), // 新数据肯定是未删除的
          ),
        );
      }
    });
  }

  /// 归档/取消归档
  Future<void> setArchived(String id, bool archived, int now) async {
    await (update(memos)..where((t) => t.id.equals(id))).write(
      MemosCompanion(
        isArchived: Value(archived),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }
}

@riverpod
Future<MemoDao> memoDao(Ref ref) async {
  final db = await ref.watch(memoDatabaseProvider.future);
  return MemoDao(db);
}
