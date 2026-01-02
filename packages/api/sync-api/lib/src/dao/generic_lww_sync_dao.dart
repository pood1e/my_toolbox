import 'package:drift/drift.dart';

import '../domain/lww_sync_table.dart';
import 'core_sync_table.dart';

// =============================================================================
// Level 1: 通用基础 Mixin (Generic)
// =============================================================================
mixin GenericLwwSyncDaoMixin<DB extends GeneratedDatabase, T extends Table, D>
    on DatabaseAccessor<DB> {
  TableInfo get table;

  /// 2. 抽象方法: ID 匹配逻辑
  Expression<bool> whereId(T t, String id);

  /// 🔒 私有辅助: 将 table 视为表定义 T
  /// 运行时 table 是 $ActivitiesTable，它继承自 Activities (T)，所以转换是安全的
  T get _asTable => table as T;

  /// 🔒 私有辅助: 将 table 视为 LwwSyncTable
  LwwSyncTable get _lww => table as LwwSyncTable;

  // --- Local Write ---

  Future<void> saveLocal(Insertable<D> entry, int nowMs) async {
    // into(table) 接受 Raw TableInfo
    await into(table).insert(entry, onConflict: DoUpdate((old) => entry));
  }

  // --- Sync Read ---

  Future<List<D>> getDirtyItems() {
    // select(table) 接受 Raw TableInfo，返回 SimpleSelectStatement<dynamic, D>
    // 我们手动 cast 一下列定义
    return (select(
      table,
    )..where((_) => _lww.isDirty.equals(true))).get().then((v) => v.cast<D>());
  }

  Future<int> getMaxCursor() async {
    final query = selectOnly(table)..addColumns([_lww.serverUpdatedAt.max()]);

    final result = await query.getSingle();
    return result.read(_lww.serverUpdatedAt.max()) ?? 0;
  }

  // --- Sync Write ---

  Future<void> markSynced(
    Map<String, int> ackedItems,
    Map<String, int> snapshots,
  ) async {
    await batch((batch) {
      for (final entry in ackedItems.entries) {
        final id = entry.key;
        final newServerTime = entry.value;
        final sentTime = snapshots[id];

        if (sentTime == null) continue;

        batch.update(
          table,
          RawValuesInsertable({
            _lww.isDirty.name: const Constant(false),
            _lww.serverUpdatedAt.name: Constant(newServerTime),
          }),
          where: (t) {
            // t 这里是 dynamic (因为 table 是 Raw)，我们需要强转为 T 来使用 whereId
            // 或者直接用我们保存的 _asTable 和 _lww (Drift 生成的类单例特性)
            return whereId(_asTable, id) & _lww.updatedAt.equals(sentTime);
          },
        );
      }
    });
  }

  Future<void> applyRemote<C extends UpdateCompanion<D>>(
    List<C> remoteCompanions, {
    required String Function(C) getId,
    required int Function(C) getServerUpdatedAt,
  }) async {
    await batch((batch) async {
      for (final companion in remoteCompanions) {
        final id = getId(companion);
        final remoteTime = getServerUpdatedAt(companion);

        final checkQuery = selectOnly(table)
          ..addColumns([_lww.serverUpdatedAt])
          ..where(whereId(_asTable, id));

        final checkRow = await checkQuery.getSingleOrNull();

        if (checkRow != null) {
          final localServerTime = checkRow.read(_lww.serverUpdatedAt) ?? 0;
          if (localServerTime >= remoteTime) continue;
        }

        batch.insert(
          table,
          companion,
          onConflict: DoUpdate((old) => companion),
        );
      }
    });
  }
}

// =============================================================================
// Level 2: 标准实体 Mixin (Standard)
// =============================================================================
mixin StandardLwwSyncDaoMixin<
  DB extends GeneratedDatabase,
  T extends CoreSyncTable,
  D
>
    on DatabaseAccessor<DB>, GenericLwwSyncDaoMixin<DB, T, D> {
  @override
  Expression<bool> whereId(T t, String id) => t.id.equals(id);

  Future<void> deleteLocal(String id, int nowMs) async {
    // update(table) 返回 UpdateStatement<dynamic, dynamic>
    final query = update(table)..where((_) => _asTable.id.equals(id));

    await query.write(
      RawValuesInsertable({
        _asTable.deletedAt.name: Constant(nowMs),
        _asTable.updatedAt.name: Constant(nowMs),
        _asTable.isDirty.name: const Constant(true),
      }),
    );
  }

  Future<int> purgeSyncedSoftDeleted() async {
    return (delete(table)
          ..where((_) => _asTable.deletedAt.isNotNull())
          ..where((_) => _lww.isDirty.equals(false)))
        .go();
  }
}
