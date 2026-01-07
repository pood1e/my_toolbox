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
  List<AppUsagePatch> respFromJson(Object? json) {
    // 假设返回的是 Patch 列表
    final list = json as List<dynamic>;
    return list.map((e) => AppUsagePatch.fromJson(e)).toList();
  }

  @override
  Map<String, dynamic> reqToJson(
    DeltaSyncRequestPart<AppUsageDelta> delta,
  ) {
    return delta.toJson((usage) => usage.toJson());
  }
}

class AppUsageSyncDelegate
    extends
        SingleSyncDelegate<
          AppUsageDao,
          DeltaSyncRequestPart<AppUsageDelta>,
          List<AppUsagePatch>
        > {
  AppUsageSyncDelegate({
    required super.dio,
    required super.resourceUse,
    required DeviceIdService deviceIdService,
  }) : super(handler: AppUsageSyncHandler(deviceIdService: deviceIdService));

  @override
  String get apiPath => '/shell/app_usage/sync';

  @override
  String get resourceId => 'app_usage';
}
