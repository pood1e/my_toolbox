import 'package:app_core/object.dart';

part 'lww_sync_payload.freezed.dart';
part 'lww_sync_payload.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class LwwSyncResponsePayload<T> with _$LwwSyncResponsePayload<T> {
  const factory LwwSyncResponsePayload({
    required Map<String, int> acks,
    required List<T> changes,
  }) = _LwwSyncResponsePayload<T>;

  factory LwwSyncResponsePayload.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) => _$LwwSyncResponsePayloadFromJson(
    json,
    (e) => fromJsonT(e as Map<String, dynamic>),
  );
}

@Freezed(genericArgumentFactories: true)
abstract class LwwSyncRequestPayload<T> with _$LwwSyncRequestPayload<T> {
  const factory LwwSyncRequestPayload({
    required int cursor,
    required List<T> changes,
  }) = _LwwSyncRequestPayload<T>;

  factory LwwSyncRequestPayload.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) => _$LwwSyncRequestPayloadFromJson(
    json,
    (e) => fromJsonT(e as Map<String, dynamic>),
  );
}
