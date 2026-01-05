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

  UpdateCompanion<E> toCompanion(E e);

  Future<void> upsert(Insertable<E> entry) async {
    await into(table).insert(entry, onConflict: DoUpdate((old) => entry));
  }

  Future<List<E>> getDirties() {
    return (select(table)
          ..where((_) => (table as LwwTable).isDirty.equals(true)))
        .get()
        .then((v) => v.cast<E>());
  }

  Future<int> getMaxCursor() async {
    final query = selectOnly(table)
      ..addColumns([(table as LwwTable).serverUpdatedAt.max()]);
    final result = await query.getSingle();
    return result.read((table as LwwTable).serverUpdatedAt.max()) ?? 0;
  }

  /// 必须在commit事务中进行
  Future<void> markAsSynced(List<LwwAckUpdate> updates) async {
    await batch((batch) {
      for (final update in updates) {
        batch.update(
          table,
          RawValuesInsertable<E>({
            (table as LwwTable).isDirty.name: const Constant(false),
            (table as LwwTable).serverUpdatedAt.name: Constant(
              update.ack.serverUpdatedAt,
            ),
          }),
          where: (t) {
            return whereId(table as T, update.ack.primaryKey) &
                (table as LwwTable).updatedAt.equals(update.updatedAt);
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
                (table as LwwTable).updatedAt.isSmallerThanValue(e.updatedAt);
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

  Future<void> softDelete(List<dynamic> primaryId, int nowMs) async {
    final query = update(table)..where((_) => whereId(table as T, primaryId));

    await query.write(
      RawValuesInsertable<E>({
        (table as SoftDeleteTable).deletedAt.name: Constant(nowMs),
        (table as LwwTable).updatedAt.name: Constant(nowMs),
        (table as LwwTable).isDirty.name: const Constant(true),
      }),
    );
  }
}

/// 只有表混入了[SoftDeleteTable], dao才能混入该mixin
mixin LwwGcMixin<
  DB extends GeneratedDatabase,
  T extends LwwTable,
  E extends LwwEntity
>
    on DatabaseAccessor<DB> {
  TableInfo<T, E> get table;

  Future<int> softDeleteGc() async {
    return (delete(table)
          ..where((_) => (table as SoftDeleteTable).deletedAt.isNotNull())
          ..where((_) => (table as LwwTable).isDirty.equals(false)))
        .go();
  }
}
