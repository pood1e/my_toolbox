import 'package:app_core/object.dart';

part 'sync_envelopes.freezed.dart';
part 'sync_envelopes.g.dart';

/// Push 请求信封
/// 对应后端: SyncPushRequest
@Freezed(genericArgumentFactories: true)
abstract class SyncPushRequest<T> with _$SyncPushRequest<T> {
  const SyncPushRequest._();

  const factory SyncPushRequest({required T payload}) = _SyncPushRequest;

  factory SyncPushRequest.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$SyncPushRequestFromJson(json, fromJsonT);
}

/// Pull 响应信封
/// 对应后端: SyncResponse
@Freezed(genericArgumentFactories: true)
abstract class SyncPullResponse<T> with _$SyncPullResponse<T> {
  const SyncPullResponse._();

  const factory SyncPullResponse({
    /// 业务数据载荷
    required T payload,

    /// 新游标 utc时间
    required int cursor,
  }) = _SyncPullResponse;

  factory SyncPullResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$SyncPullResponseFromJson(json, fromJsonT);
}
