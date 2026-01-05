import 'package:data_api/data_api.dart';
import 'package:drift/drift.dart';

import 'lww_models.dart';
import 'lww_table.dart';

mixin LwwSyncDaoMixin<
  DB extends GeneratedDatabase,
  T extends LwwTable,
  E extends LwwEntity
>
    on DatabaseAccessor<DB> {
  Expression<bool> whereId(T t, List<dynamic> primaryId);

  TableInfo<T, E> get table;

  LwwTable get _lww => table as LwwTable;

  UpdateCompanion<E> toCompanion(E e);

  Future<void> upsert(Insertable<E> entry) async {
    await into(table).insert(entry, onConflict: DoUpdate((old) => entry));
  }

  Future<List<E>> getDirties() {
    return (select(
      table,
    )..where((_) => _lww.isDirty.equals(true))).get().then((v) => v.cast<E>());
  }

  Future<int> getMaxCursor() async {
    final query = selectOnly(table)..addColumns([_lww.serverUpdatedAt.max()]);
    final result = await query.getSingle();
    return result.read(_lww.serverUpdatedAt.max()) ?? 0;
  }

  /// 必须在commit事务中进行
  Future<void> markAsSynced(List<LwwAckUpdate> updates) async {
    await batch((batch) {
      for (final update in updates) {
        batch.update(
          table,
          RawValuesInsertable<E>({
            _lww.isDirty.name: const Constant(false),
            _lww.serverUpdatedAt.name: Constant(update.ack.serverUpdatedAt),
          }),
          where: (t) {
            return whereId(table as T, update.ack.primaryKey) &
                _lww.updatedAt.equals(update.updatedAt);
          },
        );
      }
    });
  }

  /// 必须在commit事务中进行
  Future<void> applyChanges(List<E> changes) async {
    await batch((batch) async {
      for (final e in changes) {
        // lww
        batch.update(
          table,
          toCompanion(e),
          where: (t) {
            return whereId(table as T, e.primaryKey) &
                _lww.updatedAt.isSmallerThanValue(e.updatedAt);
          },
        );
      }
    });
  }
}

/// 只有表混入了[SoftDeleteTable], dao才能混入该mixin
mixin LwwSoftDeleteMixin<
  DB extends GeneratedDatabase,
  T extends LwwTable,
  E extends LwwEntity
>
    on DatabaseAccessor<DB> {
  TableInfo<T, E> get table;

  Expression<bool> whereId(T t, List<dynamic> primaryId);

  LwwTable get _lww => table as LwwTable;

  SoftDeleteTable get _softDelete => table as SoftDeleteTable;

  Future<void> softDelete(List<dynamic> primaryId, int nowMs) async {
    final query = update(table)..where((_) => whereId(table as T, primaryId));

    await query.write(
      RawValuesInsertable<E>({
        _softDelete.deletedAt.name: Constant(nowMs),
        _lww.updatedAt.name: Constant(nowMs),
        _lww.isDirty.name: const Constant(true),
      }),
    );
  }
}

/// 只有表混入了[SoftDeleteTable], dao才能混入该mixin
mixin LwwGcMixin<DB extends GeneratedDatabase, T extends LwwTable>
    on DatabaseAccessor<DB> {
  TableInfo get table;

  LwwTable get _lww => table as LwwTable;

  SoftDeleteTable get _softDelete => table as SoftDeleteTable;

  Future<int> softDeleteGc() async {
    return (delete(table)
          ..where((_) => _softDelete.deletedAt.isNotNull())
          ..where((_) => _lww.isDirty.equals(false)))
        .go();
  }
}
