import 'package:data_api/data_api.dart';
import 'package:drift/drift.dart';

import '../../domain/common_sync_dao_mixin.dart';
import '../../domain/common_sync_interfaces.dart';
import '../../standard/sync_delegate_base.dart';
import 'lww_mixin.dart';
import 'lww_payload.dart';

abstract class LwwDao<
  E,
  S extends LwwSnapshot,
  ACK extends LwwAck,
  P extends LwwPayload
>
    implements
        DirtySelectSyncDao<E>,
        MaxCursorSyncDao,
        PrimaryKeyDao,
        AckPatchSyncDao<S, ACK> {
  Future<void> applyChanges(List<P> payloads);
}

abstract class StandardLwwDao<
  DB extends GeneratedDatabase,
  T extends Table,
  E,
  S extends LwwSnapshot,
  ACK extends LwwAck,
  P extends LwwPayload
>
    extends DatabaseAccessor<DB>
    with
        TableInfoMixin<T, E>,
        SoftDeleteSyncDaoMixin<DB, T, E>,
        SoftDeleteLwwDaoMixin<DB, T, E>,
        PrimaryKeyDaoMixin<T, E>,
        AckPatchSyncDaoMixin<DB, S, ACK, T, E>,
        DirtySelectSyncDaoMixin<DB, T, E>,
        MaxCursorSyncDaoMixin<DB, T, E>,
        LwwDaoSyncMixin<DB, T, E, S, ACK, P>,
        SyncTransactionalDaoMixin<DB>,
        CommonDaoMixin<DB, T, E>
    implements LwwDao<E, S, ACK, P> {
  StandardLwwDao(super.attachedDatabase);
}
