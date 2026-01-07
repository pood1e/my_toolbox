import 'package:drift/drift.dart';

import '../../standard/standard_sync_delegate.dart';
import '../../standard/standard_sync_payload.dart';
import 'coc_dao.dart';
import 'coc_payload.dart';

/// CoC 同步处理器基类
abstract class CocSyncHandler<
  DB extends GeneratedDatabase,
  T extends Table,
  E,
  S extends CocSnapshot,
  P extends CocPayload,
  ACK extends CocAck,
  DAO extends CocDao<E, S, ACK, P>
>
    extends
        StandardSyncHandler<
          DAO,
          P,
          ACK,
          CommonSyncRequestPart<P>,
          CommonSyncResponsePart<ACK, P>
        > {
  // --- 转换接口 ---
  P fromEntity(E entity);

  S fromPayload(P payload); // 用于生成 Snapshot
  ACK fromJsonACK(Map<String, dynamic> json);

  P fromJsonP(Map<String, dynamic> json);

  // --- Collect (收集) ---
  @override
  Future<CommonSyncRequestPart<P>> collect(DAO dao) async {
    final dirtyItems = await dao.getDirtyItems();
    return CommonSyncRequestPart<P>(
      cursor: await dao.getMaxCursor(),
      payloads: dirtyItems.map(fromEntity).toList(),
    );
  }

  // --- Merge (合并) ---
  @override
  Future<void> merge(
    DAO dao,
    CommonSyncResponsePart<ACK, P> resp,
    CommonSyncRequestPart<P> sentReq,
  ) async {
    // 1. 处理 ACK
    // 将发送时的 Payload 转换为 Snapshot (包含当时的 updatedAt)
    final snapshots = sentReq.payloads.map(fromPayload).toList();
    if (snapshots.isNotEmpty && resp.acks.isNotEmpty) {
      await dao.applyAcks(snapshots, resp.acks);
    }

    // 2. 处理下行 Changes
    if (resp.payloads.isNotEmpty) {
      await dao.applyChanges(resp.payloads);
    }
  }

  // --- JSON 反序列化 ---
  @override
  CommonSyncResponsePart<ACK, P> respFromJson(Object? json) {
    return CommonSyncResponsePart.fromJson(
      json as Map<String, dynamic>,
      fromJsonACK,
      fromJsonP,
    );
  }
}
