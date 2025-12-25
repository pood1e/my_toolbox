import 'package:app_core/object.dart';
import 'package:framework_api/framework_api.dart';

part 'launcher_dto.freezed.dart';
part 'launcher_dto.g.dart';

@freezed
abstract class AppUsageDto with _$AppUsageDto, SyncObject {
  const AppUsageDto._();

  const factory AppUsageDto({
    required String id,
    required String module, // 业务主键

    @DateTimeConverter() required DateTime lastUsedAt,
    @Default(0) int openCount,

    // 同步字段
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
    @DateTimeConverter() DateTime? deletedAt,
  }) = _AppUsageDto;

  factory AppUsageDto.fromJson(Map<String, dynamic> json) =>
      _$AppUsageDtoFromJson(json);
}

@freezed
abstract class LauncherSyncPayload with _$LauncherSyncPayload {
  const LauncherSyncPayload._();

  const factory LauncherSyncPayload({@Default([]) List<AppUsageDto> usages}) =
      _LauncherSyncPayload;

  factory LauncherSyncPayload.fromJson(Map<String, dynamic> json) =>
      _$LauncherSyncPayloadFromJson(json);

  bool get isEmpty => usages.isEmpty;
}
