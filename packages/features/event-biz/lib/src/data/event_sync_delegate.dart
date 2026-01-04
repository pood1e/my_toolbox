import 'package:app_core/http.dart';
import 'package:app_core/object.dart';
import 'package:framework_api/framework_api.dart';

import 'event_dao.dart';
import 'event_dto.dart';
import 'event_mapper.dart';

class EventSyncDelegate implements SyncDelegate {
  final Future<void> Function(Future<void> Function(EventDao)) _daoUse;
  final Dio _dio;

  EventSyncDelegate({
    required Future<void> Function(Future<void> Function(EventDao)) daoUse,
    required Dio dio,
  }) : _daoUse = daoUse,
       _dio = dio;

  @override
  String get resourceId => 'event';

  @override
  Future<void> sync() async {
    await _daoUse((dao) async {
      final dirtyItems = await dao.getDirtyItems();
      final request = LwwSyncRequestPayload<EventDto>(
        cursor: await dao.getMaxCursor(),
        changes: dirtyItems.map((e) => e.toDto()).toList(),
      );
      final snapshot = {for (var v in dirtyItems) v.id: v.updatedAt};

      final dioResponse = await _dio.post('/event/sync', data: request);
      final result = R<LwwSyncResponsePayload<EventDto>>.fromJson(
        dioResponse.data,
        (payload) => LwwSyncResponsePayload.fromJson(
          payload as Map<String, dynamic>,
          EventDto.fromJson,
        ),
      );
      final response = result.data;
      if (response == null) {
        return;
      }

      // =================================================================
      // 3. 回写 (Commit)
      // =================================================================
      await dao.transaction(() async {
        if (response.acks.isNotEmpty) {
          await dao.markSynced(response.acks, snapshot);
        }
        if (response.changes.isNotEmpty) {
          final companions = response.changes
              .map((d) => d.toCompanion())
              .toList();
          await dao.applyRemote(
            companions,
            getId: (c) => c.id.value,
            getServerUpdatedAt: (c) => c.serverUpdatedAt.value,
          );
        }
      });

      // =================================================================
      // 4. GC
      // =================================================================
      await dao.purgeSyncedSoftDeleted();
    });
  }
}
