import 'package:app_core/http.dart';
import 'package:app_core/object.dart';
import 'package:drift/drift.dart';

import '../domain/sync_delegate.dart';
import 'lww_dao.dart';
import 'lww_models.dart';
import 'lww_payload.dart';
import 'lww_table.dart';

String _idHash(List<dynamic> primaryId) {
  return primaryId.join('@');
}

abstract class LwwSyncDelegateBase<
  DB extends GeneratedDatabase,
  T extends LwwTable,
  E extends LwwEntity,
  DTO extends LwwObject,
  ACK extends LwwAck
>
    implements SyncDelegate {
  final Future<void> Function(Future<void> Function(LwwSyncDaoMixin<DB, T, E>))
  _daoUse;
  final Dio _dio;

  LwwSyncDelegateBase({
    required Future<void> Function(
      Future<void> Function(LwwSyncDaoMixin<DB, T, E>),
    )
    daoUse,
    required Dio dio,
  }) : _daoUse = daoUse,
       _dio = dio;

  DTO toDto(E entity);

  E toEntity(DTO dto);

  DTO dtoFromJson(Map<String, dynamic> json);

  ACK ackFromJson(Map<String, dynamic> json);

  String get apiPath;

  Future<void> otherSyncAction(LwwSyncDaoMixin<DB, T, E> dao) async {}

  @override
  Future<void> sync() async {
    await _daoUse((dao) async {
      final dirtyItems = await dao.getDirties();
      final request = LwwRequestPayload<DTO>(
        cursor: await dao.getMaxCursor(),
        changes: dirtyItems.map(toDto).toList(),
      );
      final snapshot = {
        for (var v in dirtyItems) _idHash(v.primaryKey): v.updatedAt,
      };

      final dioResponse = await _dio.post(apiPath, data: request);
      final result = R<LwwResponsePayload<DTO, ACK>>.fromJson(
        dioResponse.data,
        (payload) => LwwResponsePayload<DTO, ACK>.fromJson(
          payload as Map<String, dynamic>,
          dtoFromJson,
          ackFromJson,
        ),
      );
      final response = result.data;
      if (response != null) {
        final ackUpdates = <LwwAckUpdate>[];
        for (final ack in response.acks) {
          final idHash = _idHash(ack.primaryKey);
          final snapshotValue = snapshot[idHash]!;
          ackUpdates.add(LwwAckUpdate(ack: ack, updatedAt: snapshotValue));
        }
        await dao.transaction(() async {
          if (ackUpdates.isNotEmpty) {
            await dao.markAsSynced(ackUpdates);
          }
          if (response.changes.isNotEmpty) {
            await dao.applyChanges(response.changes.map(toEntity).toList());
          }
        });
      }

      await otherSyncAction(dao);
    });
  }
}

abstract class LwwSoftDeleteSyncDelegateBase<
  DB extends GeneratedDatabase,
  T extends LwwTable,
  E extends LwwEntity,
  DTO extends LwwObject,
  ACK extends LwwAck
>
    extends LwwSyncDelegateBase<DB, T, E, DTO, ACK> {
  LwwSoftDeleteSyncDelegateBase({required super.daoUse, required super.dio});

  @override
  Future<void> otherSyncAction(LwwSyncDaoMixin<DB, T, E> dao) async {
    final gcDao = dao as LwwGcMixin;
    await gcDao.softDeleteGc();
  }
}
