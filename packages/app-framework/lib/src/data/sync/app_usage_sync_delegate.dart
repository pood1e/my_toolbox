import 'package:app_core/http.dart';
import 'package:framework_api/framework_api.dart';

import '../launcher/app_usage_dao.dart';
import '../launcher/app_usage_dto.dart';

class AppUsageSyncDelegate implements SyncDelegate {
  final AppUsageDao _dao;
  final Dio _dio;
  final ServerTimeService _serverTimeService;
  final DeviceIdService _deviceIdService;

  AppUsageSyncDelegate({
    required AppUsageDao dao,
    required Dio dio,
    required ServerTimeService serverTimeService,
    required DeviceIdService deviceIdService,
  }) : _dao = dao,
       _dio = dio,
       _serverTimeService = serverTimeService,
       _deviceIdService = deviceIdService;

  @override
  String get resourceId => 'app_usage';

  @override
  Future<int> sync(int? cursor) async {
    final locktime = _serverTimeService.nowMs;
    final localPayload = await _dao.lockAndGetPayload(
      locktime,
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
      await _dao.onSuccess();
    }

    final data = SyncResponse<List<AppUsagePatch>>.fromJson(
      response.data,
      (json) => (json as List)
          .map((e) => AppUsagePatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (data.payload != null) {
      await _dao.applyRemoteStats(data.payload!);
    }

    return data.cursor;
  }
}
