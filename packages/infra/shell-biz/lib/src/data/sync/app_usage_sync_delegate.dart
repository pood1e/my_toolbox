import 'package:app_core/http.dart';
import 'package:app_core/object.dart';
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
  })
      : _dio = dio,
        _deviceIdService = deviceIdService,
        _daoUse = daoUse;

  @override
  String get resourceId => 'app_usage';

  @override
  Future<void> sync() async {
    await _daoUse((dao) async {
      await _syncInternal(dao);
      while (await dao.checkHasChanges()) {
        await _syncInternal(dao);
      }
    });
  }

  Future<void> _syncInternal(AppUsageDao dao) async {
    final cursor = await dao.getMaxCursor();
    final localPayload = await dao.lockAndGetPayload(
      await _deviceIdService.getDeviceId(),
    );

    final response = await _dio.post(
      '/framework/app_usage/sync',
      data: AppUsageSyncRequest<SyncDelta<AppUsageDelta>>(
        cursor: cursor,
        payload: localPayload,
      ).toJson((t) => t.toJson((x) => x.toJson())),
    );

    if (localPayload != null) {
      await dao.onSuccess();
    }

    final result = R.fromJson(response.data, (json) =>
        (json as List).map((e) =>
            AppUsagePatch.fromJson(e as Map<String, dynamic>))
            .toList());
    await dao.applyRemoteStats(result.data!);
  }
}
