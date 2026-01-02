import 'package:app_core/object.dart';

import 'reality_dtos.dart';

part 'sync_dtos.freezed.dart';
part 'sync_dtos.g.dart';

/// 客户端发起的同步请求
@freezed
abstract class SyncRequest with _$SyncRequest {
  const factory SyncRequest({
    // 客户端持有的各表游标 { "activities": 170000, ... }
    required Map<String, int> cursors,

    // 上传的脏数据
    required SyncPayload changes,
  }) = _SyncRequest;

  factory SyncRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncRequestFromJson(json);
}

/// 服务端返回的响应
@freezed
abstract class SyncResponse with _$SyncResponse {
  const factory SyncResponse({
    // 省流确认: { "activities": ["id1", "id2"] }
    // 客户端收到后将本地 isDirty 置为 false
    Map<String, Map<String, int>>? ackedIds,

    // 下行变更数据 (别人改的 + 回声)
    SyncPayload? changes,
  }) = _SyncResponse;

  factory SyncResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncResponseFromJson(json);
}

/// 数据负载 (复用于 Push 和 Changes)
@freezed
abstract class SyncPayload with _$SyncPayload {
  const factory SyncPayload({
    @Default([]) List<ActivityDto> activities,
    @Default([]) List<ActivityLogDto> activityLogs,
    @Default([]) List<ActivityShortcutDto> activityShortcuts,
  }) = _SyncPayload;

  factory SyncPayload.fromJson(Map<String, dynamic> json) =>
      _$SyncPayloadFromJson(json);
}
