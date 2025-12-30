import 'package:app_core/http.dart';
import 'package:framework_api/framework_api.dart';

import '../launcher/app_usage_dao.dart';
import '../launcher/app_usage_dto.dart';

class AppUsageSyncDelegate implements SyncDelegate {
  final Dio _dio;
  final DeviceIdService _deviceIdService;

  final Future<void> Function(Future<void> Function(AppUsageDao)) _daoUse;

  AppUsageSyncDelegate({
    required Dio dio,
    required DeviceIdService deviceIdService,
    required Future<void> Function(Future<void> Function(AppUsageDao)) daoUse,
  }) : _dio = dio,
       _deviceIdService = deviceIdService,
       _daoUse = daoUse;

  @override
  String get resourceId => 'app_usage';

  @override
  Future<void> sync(int? cursor, Future<void> Function(int) cursorSaver) async {
    await _daoUse((dao) async {
      int newCursor = await _syncInternal(dao, cursor);
      await cursorSaver(newCursor);
      while (await dao.checkHasChanges()) {
        newCursor = await _syncInternal(dao, newCursor);
        await cursorSaver(newCursor);
      }
    });
  }

  Future<int> _syncInternal(AppUsageDao dao, int? cursor) async {
    final localPayload = await dao.lockAndGetPayload(
      await _deviceIdService.getDeviceId(),
    );

    final response = await _dio.post(
      '/framework/app_usage/sync',
      data: SyncRequest<SyncDelta<AppUsageDelta>>(
        cursor: cursor,
        payload: localPayload,
      ).toJson((t) => t.toJson((x) => x.toJson())),
    );

    if (localPayload != null) {
      await dao.onSuccess();
    }

    final data = SyncResponse<List<AppUsagePatch>>.fromJson(
      response.data,
      (json) => (json as List)
          .map((e) => AppUsagePatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (data.payload != null) {
      await dao.applyRemoteStats(data.payload!);
    }

    return data.cursor;
  }
}
