import 'package:data_api/data_api.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../domain/common_sync_dao_mixin.dart';
import '../../domain/common_sync_table_mixin.dart';
import 'coc_dao.dart';
import 'coc_payload.dart';

/// CoC 策略表结构
/// 建议索引:
/// CREATE INDEX idx_xx_coc_dirty ON xx(is_dirty);
/// CREATE INDEX idx_xx_coc_cursor ON xx(server_updated_at);
mixin CocTableMixin on Table
    implements
        IsDirtySyncTableMixin,
        CursorSyncTableMixin,
        UpdatedAtTableMixin {
  IntColumn get version => integer().withDefault(const Constant(1))();

  TextColumn get conflictRefId => text().nullable()();
}

/// CoC DAO 实现 Mixin
mixin CocDaoSyncMixin<
  DB extends GeneratedDatabase,
  T extends Table,
  E,
  S extends CocSnapshot,
  ACK extends CocAck,
  P extends CocPayload
>
    on
        DatabaseAccessor<DB>,
        TableInfoMixin<T, E>,
        PrimaryKeyDaoMixin<T, E>, // 提供 whereById
        AckPatchSyncDaoMixin<DB, S, ACK, T, E>, // 提供 applyAcks 框架
        DirtySelectSyncDaoMixin<DB, T, E>, // 提供 getDirties
        MaxCursorSyncDaoMixin<DB, T, E> // 提供 getMaxCursor
    implements CocDao<E, S, ACK, P> {
  // --- 列查找 ---
  GeneratedColumn<int> get updatedAtColumn => findColumn('updated_at');

  GeneratedColumn<int> get versionColumn => findColumn('version');

  GeneratedColumn<int> get serverUpdatedAtColumn =>
      findColumn('server_updated_at');

  // --- AckPatchSyncDaoMixin 重写 (核心逻辑) ---

  /// CoC 的匹配逻辑：
  /// 不仅 ID 要匹配，Snapshot 中的 updatedAt 必须等于数据库当前的 updatedAt。
  /// 这意味着在同步期间，用户没有在本地修改过这条数据。
  @override
  Expression<bool> match(S snapshot) {
    return whereById(snapshot.primaryId) &
        updatedAtColumn.equals(snapshot.updatedAt);
  }

  /// CoC 的更新逻辑：
  /// 清除 dirty，更新 cursor，同时更新 version
  @override
  Insertable<E> ackFields(ACK ack) {
    return RawValuesInsertable<E>({
      isDirtyColumn.name: const Constant(false),
      serverUpdatedAtColumn.name: Constant(ack.serverUpdatedAt),
      versionColumn.name: Constant(ack.version),
    });
  }

  // --- 抽象方法：由子类实现 P -> Companion 的转换 ---
  @protected
  Insertable<E> toCocCompanion(P payload);

  // --- Apply Changes (下行处理) ---

  @override
  Future<void> applyChanges(List<P> payloads) async {
    await batch((batch) async {
      for (final payload in payloads) {
        // 使用 insertOnConflictUpdate (Upsert)
        // 注意：具体的冲突策略(如 version check) 通常由服务端解决，
        // 下行数据通常代表"最终结果"，直接覆盖本地。
        batch.insert(
          table,
          toCocCompanion(payload),
          onConflict: DoUpdate((old) => toCocCompanion(payload)),
        );
      }
    });
  }
}

/// CoC 软删除支持
mixin SoftDeleteCocDaoMixin<DB extends GeneratedDatabase, T extends Table, E>
    on SoftDeleteSyncDaoMixin<DB, T, E> {
  GeneratedColumn<int> get updatedAtColumn => findColumn('updated_at');

  @override
  Insertable<E> softDeleteUpdateFields(int nowMs) {
    return RawValuesInsertable<E>({
      deletedAtColumn.name: Constant(nowMs),
      // 软删除时也更新 updatedAt，确保正在进行的 Sync 如果由旧数据也会失败(Snapshot不匹配)
      updatedAtColumn.name: Constant(nowMs),
      isDirtyColumn.name: const Constant(true),
    });
  }
}
