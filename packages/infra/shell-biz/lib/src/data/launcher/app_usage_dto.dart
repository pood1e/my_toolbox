import 'package:app_core/object.dart';

part 'app_usage_dto.freezed.dart';
part 'app_usage_dto.g.dart';

@freezed
abstract class AppUsageDelta with _$AppUsageDelta {
  const factory AppUsageDelta({
    required String module,
    required int deltaCount,
    required int lastUsedAt,
  }) = _AppUsageDelta;

  factory AppUsageDelta.fromJson(Map<String, dynamic> json) =>
      _$AppUsageDeltaFromJson(json);
}

@freezed
abstract class AppUsagePatch with _$AppUsagePatch {
  const factory AppUsagePatch({
    required String module,
    required int totalCount,
    required int lastUsedAt,
    required int serverUpdatedAt
  }) = _AppUsagePatch;

  factory AppUsagePatch.fromJson(Map<String, dynamic> json) =>
      _$AppUsagePatchFromJson(json);
}

@Freezed(genericArgumentFactories: true)
abstract class AppUsageSyncRequest<T> with _$AppUsageSyncRequest<T> {
  const AppUsageSyncRequest._();

  const factory AppUsageSyncRequest({int? cursor, T? payload}) = _AppUsageSyncRequest;

  factory AppUsageSyncRequest.fromJson(
      Map<String, dynamic> json,
      T Function(Object? json) fromJsonT,
      ) => _$AppUsageSyncRequestFromJson(json, fromJsonT);
}