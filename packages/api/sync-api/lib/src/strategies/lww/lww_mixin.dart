import 'package:data_api/data_api.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../domain/common_sync_dao_mixin.dart';
import '../../domain/common_sync_table_mixin.dart';
import 'lww_dao.dart';
import 'lww_payload.dart';

/// lww策略
/// 本地表一般带serverUpdatedAt, isDirty, updatedAt
mixin LwwTableMixin
    on
        Table,
        IsDirtySyncTableMixin,
        CursorSyncTableMixin,
        UpdatedAtTableMixin {}

mixin LwwDaoSyncMixin<
  DB extends GeneratedDatabase,
  T extends Table,
  E,
  S extends LwwSnapshot,
  ACK extends LwwAck,
  P extends LwwPayload
>
    on
        DatabaseAccessor<DB>,
        TableInfoMixin<T, E>,
        AckPatchSyncDaoMixin<DB, S, ACK, T, E>,
        DirtySelectSyncDaoMixin<DB, T, E>,
        MaxCursorSyncDaoMixin<DB, T, E>
    implements LwwDao<E, S, ACK, P> {
  GeneratedColumn<int> get updatedAtColumn => findColumn('updated_at');

  @override
  Expression<bool> match(S snapshot) {
    return whereById(snapshot.primaryId) &
        updatedAtColumn.equals(snapshot.updatedAt);
  }

  @override
  Insertable<E> ackFields(ACK ack) {
    return RawValuesInsertable<E>({
      isDirtyColumn.name: const Constant(false),
      cursorColumn.name: Constant(ack.serverUpdatedAt),
    });
  }

  @protected
  Insertable<E> toLwwComponion(P payload);

  @override
  Future<void> applyChanges(List<P> payloads) async {
    await batch((batch) async {
      for (final payload in payloads) {
        batch.update(
          table,
          toLwwComponion(payload),
          where: (_) {
            return whereById(payload.primaryId) &
                updatedAtColumn.isSmallerThanValue(payload.updatedAt);
          },
        );
      }
    });
  }
}

/// lww软删除
mixin SoftDeleteLwwDaoMixin<DB extends GeneratedDatabase, T extends Table, E>
    on SoftDeleteSyncDaoMixin<DB, T, E> {
  GeneratedColumn<int> get updatedAtColumn;

  @override
  Insertable<E> softDeleteUpdateFields(int nowMs) {
    return RawValuesInsertable<E>({
      deletedAtColumn.name: Constant(nowMs),
      updatedAtColumn.name: Constant(nowMs),
      isDirtyColumn.name: const Constant(true),
    });
  }
}
