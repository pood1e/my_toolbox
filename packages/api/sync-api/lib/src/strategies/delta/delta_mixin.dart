// File: strategies/delta/delta_table.dart
import 'package:data_api/data_api.dart';
import 'package:drift/drift.dart';

import '../../../sync_api.dart';

mixin DeltaTableMixin on Table implements CursorSyncTableMixin {}

mixin SyncSequenceTableMixin on Table {
  TextColumn get moduleId => text()();

  IntColumn get sequence => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {moduleId};
}

/// Delta 两阶段提交 (2PC) DAO Mixin
/// 泛型 SEQ 指向 SyncSequenceTable
mixin DeltaDao2PCMixin<
  DB extends GeneratedDatabase,
  T extends Table,
  E,
  SEQ extends SyncSequenceTableMixin,
  SE
>
    on
        DatabaseAccessor<DB>,
        TableInfoMixin<T, E>,
        MaxCursorSyncDaoMixin<DB, T, E>
    implements DeltaOpInterface<E> {
  // 需要子类提供 Sequence 表的信息
  TableInfo<SEQ, SE> get sequenceTable;

  // 模块 ID，用于 Sequence 区分
  String get syncModuleId;

  // ===========================================================================
  // 1. Push 流程: Lock & Get Payload
  // ===========================================================================

  /// 准备发送数据
  /// 自动处理 Sequence 自增和数据锁定
  Future<DeltaSyncRequestPart<PUSH>> lockAndGetPayload<PUSH>(
    String deviceId,
    PUSH Function(E entity) mapper,
  ) async {
    final cursor = await getMaxCursor();

    // A. 获取 Sequence 元数据
    var meta =
        await (select(sequenceTable as TableInfo)..where(
              (t) =>
                  (t as SyncSequenceTableMixin).moduleId.equals(syncModuleId),
            ))
            .getSingleOrNull();

    // 初始化 Sequence
    if (meta == null) {
      await into(sequenceTable as TableInfo).insert(
        RawValuesInsertable({
          'module_id': Constant(syncModuleId),
          'sequence': const Constant(0),
        }),
      );
      meta =
          await (select(sequenceTable as TableInfo)..where(
                (t) =>
                    (t as SyncSequenceTableMixin).moduleId.equals(syncModuleId),
              ))
              .getSingle();
    }

    int currentSequence = (meta as dynamic).sequence;

    // B. 检查状态
    final state = await checkState();

    if (state.hasLocked) {
      // [重试模式]
      // 存在 Locked 数据，说明上次发送失败或未收到 ACK。
      // 保持 Sequence 不变，直接重发 Locked 数据。
      // logger.i('♻️ [Delta] Retry sequence: $currentSequence');
    } else if (state.hasUnsync) {
      // [新批次模式]
      // 无 Locked，有 Unsync。开启新批次。
      currentSequence += 1;

      // 1. 更新 Sequence
      await (update(sequenceTable as TableInfo)..where(
            (t) => (t as SyncSequenceTableMixin).moduleId.equals(syncModuleId),
          ))
          .write(
            RawValuesInsertable<SE>({'sequence': Constant(currentSequence)}),
          );

      // 2. 执行状态跃迁 (Unsync -> Locked)
      // 具体移哪些字段，由子类实现
      await moveUnsyncToLocked();
    } else {
      return DeltaSyncRequestPart<PUSH>(cursor: cursor);
    }

    // C. 构建 Payload
    final lockedItems = await getLockedItems();

    return DeltaSyncRequestPart<PUSH>(
      sequence: currentSequence,
      deviceId: deviceId,
      deltas: lockedItems.map(mapper).toList(),
      cursor: cursor,
    );
  }

  // ===========================================================================
  // 2. Push 流程: Commit (Success)
  // ===========================================================================

  /// 发送成功后调用
  Future<void> onPushSuccess() async {
    // 收到 ACK，说明服务端已接收 Locked 部分，本地可以安全清除
    await clearLocked();
  }
}
