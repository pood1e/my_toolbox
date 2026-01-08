import 'package:data_api/data_api.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../standard/standard_sync_payload.dart';
import 'common_sync_interfaces.dart';

extension SyncKeyExtension on List<dynamic> {
  String get toSyncKey => join('@');
}

mixin MaxCursorSyncDaoMixin<DB extends GeneratedDatabase, T extends Table, E>
    on DatabaseAccessor<DB>
    implements MaxCursorSyncDao, TableGetter<T, E>, ColumnFinder {
  @protected
  GeneratedColumn<int> get cursorColumn => findColumn('server_updated_at');

  @override
  Future<int> getMaxCursor() async {
    final query = selectOnly(table)..addColumns([cursorColumn.max()]);
    final result = await query.getSingle();
    return result.read(cursorColumn.max()) ?? 0;
  }
}

mixin SoftDeleteSyncDaoMixin<DB extends GeneratedDatabase, T extends Table, E>
    on DatabaseAccessor<DB>
    implements
        SoftDeleteSyncDao,
        ColumnFinder,
        PrimaryKeyDao,
        TableGetter<T, E> {
  @protected
  GeneratedColumn<int> get deletedAtColumn => findColumn('deleted_at');

  @protected
  GeneratedColumn<bool> get isDirtyColumn => findColumn('is_dirty');

  @protected
  Insertable<E> softDeleteUpdateFields(int nowMs) {
    return RawValuesInsertable<E>({
      deletedAtColumn.name: Constant(nowMs),
      isDirtyColumn.name: const Constant(true),
    });
  }

  @override
  Future<void> softDelete(List<dynamic> id, int nowMs) async {
    final query = update(table)..where((_) => whereById(id));

    await query.write(softDeleteUpdateFields(nowMs));
  }

  @override
  Future<void> gc() async {
    final query = delete(table)
      ..where((_) => deletedAtColumn.isNotNull() & isDirtyColumn.equals(false));
    await query.go();
  }
}

mixin DirtySelectSyncDaoMixin<DB extends GeneratedDatabase, T extends Table, E>
    on DatabaseAccessor<DB>
    implements DirtySelectSyncDao<E>, ColumnFinder, TableGetter<T, E> {
  @protected
  GeneratedColumn<bool> get isDirtyColumn => findColumn('is_dirty');

  @override
  Future<List<E>> getDirtyItems() {
    return (select(
      table,
    )..where((_) => isDirtyColumn.equals(true))).get().then((v) => v.cast<E>());
  }
}

mixin AckPatchSyncDaoMixin<
  DB extends GeneratedDatabase,
  S extends SyncRequestSnapshot,
  ACK extends StandardSyncResponseAck,
  T extends Table,
  E
>
    on DatabaseAccessor<DB>
    implements
        AckPatchSyncDao<S, ACK>,
        ColumnFinder,
        TableGetter<T, E>,
        PrimaryKeyDao {
  @protected
  GeneratedColumn<bool> get isDirtyColumn => findColumn('is_dirty');

  Expression<bool> match(S snapshot) {
    return whereById(snapshot.primaryId);
  }

  Insertable<E> ackFields(ACK ack) {
    return RawValuesInsertable<E>({isDirtyColumn.name: const Constant(false)});
  }

  @override
  Future<void> applyAcks(List<S> snapshots, List<ACK> acks) async {
    final snapshotMap = {
      for (final snapshot in snapshots) snapshot.primaryId.toSyncKey: snapshot,
    };
    await batch((batch) {
      for (final ack in acks) {
        final snapshot = snapshotMap[ack.primaryId.toSyncKey];
        if (snapshot == null) {
          continue;
        }
        batch.update(
          table,
          ackFields(ack),
          where: (_) {
            return match(snapshot);
          },
        );
      }
    });
  }
}
