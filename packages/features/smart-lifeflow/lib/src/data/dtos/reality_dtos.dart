import 'package:app_core/object.dart';

part 'reality_dtos.freezed.dart';
part 'reality_dtos.g.dart';

// =============================================================================
// 1. ActivityDto (行为分类)
// =============================================================================

@freezed
abstract class ActivityDto with _$ActivityDto {
  const factory ActivityDto({
    required String id,
    required String name,
    String? icon,
    String? colorHex,
    @Default(false) bool isArchived,

    // Sync Meta
    required int createdAt,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _ActivityDto;

  factory ActivityDto.fromJson(Map<String, dynamic> json) =>
      _$ActivityDtoFromJson(json);
}

// =============================================================================
// 2. ActivityLogDto (行为流水 - 纯净版)
// =============================================================================
@freezed
abstract class ActivityLogDto with _$ActivityLogDto {
  const factory ActivityLogDto({
    required String id,
    required String activityId,

    // 物理时间轴
    required int startTime,
    int? endTime,
    String? note,

    // Sync Meta
    required int createdAt,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _ActivityLogDto;

  factory ActivityLogDto.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogDtoFromJson(json);
}

// =============================================================================
// 3. ActivityShortcutDto (快捷方式)
// =============================================================================
@freezed
abstract class ActivityShortcutDto with _$ActivityShortcutDto {
  const factory ActivityShortcutDto({
    // 主键即 activityId
    required String activityId,

    @Default(0.0) double sortOrder,

    // Sync Meta
    // 注意: Shortcut 没有 createdAt (它混入的是 LwwSyncTable + SoftDelete)
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _ActivityShortcutDto;

  factory ActivityShortcutDto.fromJson(Map<String, dynamic> json) =>
      _$ActivityShortcutDtoFromJson(json);
}
