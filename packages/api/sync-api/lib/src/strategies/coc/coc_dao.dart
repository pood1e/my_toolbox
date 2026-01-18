// File: strategies/coc/coc_dao.dart
import 'package:data_api/data_api.dart';
import 'package:drift/drift.dart';

import '../../domain/common_sync_dao_mixin.dart';
import '../../domain/common_sync_interfaces.dart';
import '../../standard/sync_delegate_base.dart';
import 'coc_mixin.dart';
import 'coc_payload.dart';

/// CoC DAO 接口定义
abstract class CocDao<
  E,
  S extends CocSnapshot,
  ACK extends CocAck,
  P extends CocPayload
>
    implements
        DirtySelectSyncDao<E>,
        MaxCursorSyncDao,
        PrimaryKeyDao,
        AckPatchSyncDao<S, ACK> {
  Future<void> applyChanges(List<P> payloads);
}

abstract class StandardCocDao<
  DB extends GeneratedDatabase,
  T extends Table,
  E,
  S extends CocSnapshot,
  ACK extends CocAck,
  P extends CocPayload
>
    extends DatabaseAccessor<DB>
    with
        TableInfoMixin<T, E>,
        SoftDeleteSyncDaoMixin<DB, T, E>,
        SoftDeleteCocDaoMixin<DB, T, E>,
        PrimaryKeyDaoMixin<T, E>,
        AckPatchSyncDaoMixin<DB, S, ACK, T, E>,
        DirtySelectSyncDaoMixin<DB, T, E>,
        MaxCursorSyncDaoMixin<DB, T, E>,
        CocDaoSyncMixin<DB, T, E, S, ACK, P>,
        SyncTransactionalDaoMixin<DB>,
        CommonDaoMixin<DB, T, E>
    implements CocDao<E, S, ACK, P> {
  StandardCocDao(super.attachedDatabase);
}
