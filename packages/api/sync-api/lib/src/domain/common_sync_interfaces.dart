import '../standard/standard_sync_payload.dart';

/// [DAO 能力] 获取最大游标
abstract class MaxCursorSyncDao {
  Future<int> getMaxCursor();
}

/// [DAO 能力] 软删除
abstract class SoftDeleteSyncDao {
  Future<void> softDelete(List<dynamic> id, int nowMs);

  /// 清理已同步的软删除数据
  Future<void> gc();
}

/// [DAO 能力] 获取脏数据
abstract class DirtySelectSyncDao<E> {
  Future<List<E>> getDirtyItems();
  Future<bool> hasDirtyItems();
}

abstract class AckPatchSyncDao<
  S extends SyncRequestSnapshot,
  ACK extends StandardSyncResponseAck
> {
  Future<void> applyAcks(
    List<S> snapshots,
    List<ACK> acks,
  );
}
