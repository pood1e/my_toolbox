import 'package:drift/drift.dart';

import '../../standard/standard_sync_delegate.dart';
import '../../standard/standard_sync_payload.dart';
import 'lww_dao.dart';
import 'lww_payload.dart';

abstract class LwwSyncHandler<
  DB extends GeneratedDatabase,
  T extends Table,
  E,
  S extends LwwSnapshot,
  P extends LwwPayload,
  ACK extends LwwAck,
  DAO extends LwwDao<E, S, ACK, P>
>
    extends
        StandardSyncHandler<
          DAO,
          P,
          ACK,
          CommonSyncRequestPart<P>,
          CommonSyncResponsePart<ACK, P>
        > {
  P fromEntity(E entity);

  Insertable<E> fromServerPayload(P payload);

  S fromPayload(P payload);

  ACK fromJsonACK(Map<String, dynamic> json);

  P fromJsonP(Map<String, dynamic> json);

  @override
  Future<CommonSyncRequestPart<P>> collect(DAO dao) async {
    final dirtyItems = await dao.getDirtyItems();
    return CommonSyncRequestPart<P>(
      cursor: await dao.getMaxCursor(),
      payloads: dirtyItems.map(fromEntity).toList(),
    );
  }

  @override
  Future<void> merge(
    DAO dao,
    CommonSyncResponsePart<ACK, P> resp,
    CommonSyncRequestPart<P> sentReq,
  ) async {
    final acks = resp.acks;
    final snapshots = sentReq.payloads.map(fromPayload).toList();
    if (snapshots.isNotEmpty && acks.isNotEmpty) {
      await dao.applyAcks(snapshots, acks);
    }
    if (resp.payloads.isNotEmpty) {
      await dao.applyChanges(resp.payloads);
    }
  }

  @override
  CommonSyncResponsePart<ACK, P> respFromJson(Object? json) {
    return CommonSyncResponsePart.fromJson(
      json as Map<String, dynamic>,
      fromJsonACK,
      fromJsonP,
    );
  }
}
