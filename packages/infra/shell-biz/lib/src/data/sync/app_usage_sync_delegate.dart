import 'package:framework_api/framework_api.dart';

import '../launcher/app_usage_dao.dart';
import '../launcher/app_usage_dto.dart';
import '../shell_database.dart';

class AppUsageSyncHandler
    extends
        DeltaSyncHandler<
          AppUsageDao,
          AppUsageEntity,
          AppUsageDelta,
          AppUsagePatch
        > {
  AppUsageSyncHandler({required super.deviceIdService});

  @override
  AppUsageDelta toPushDTO(AppUsageEntity entity) {
    return AppUsageDelta(
      module: entity.module,
      deltaCount: entity.lockedCount, // 发送的是 locked 部分
      lastUsedAt: entity.lastUsedAt,
    );
  }

  // --- Merge Logic ---
  @override
  Future<void> applyRemotePatches(
    AppUsageDao dao,
    List<AppUsagePatch> patches,
  ) async {
    await dao.applyPatches(patches);
  }

  @override
  DeltaSyncResponsePart<AppUsagePatch> respFromJson(Object? json) {
    return DeltaSyncResponsePart<AppUsagePatch>.fromJson(
      json as Map<String, dynamic>,
      (l) => AppUsagePatch.fromJson(l as Map<String, dynamic>),
    );
  }

  @override
  Map<String, dynamic> reqToJson(DeltaSyncRequestPart<AppUsageDelta> delta) {
    return delta.toJson((usage) => usage.toJson());
  }
}

class AppUsageSyncDelegate
    extends
        SingleSyncDelegate<
          AppUsageDao,
          DeltaSyncRequestPart<AppUsageDelta>,
          DeltaSyncResponsePart<AppUsagePatch>
        > {
  AppUsageSyncDelegate({
    required super.dio,
    required super.resourceUse,
    required DeviceIdService deviceIdService,
  }) : super(handler: AppUsageSyncHandler(deviceIdService: deviceIdService));

  @override
  String get resourceId => 'app_usage';
}
