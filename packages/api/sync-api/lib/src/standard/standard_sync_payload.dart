import 'package:app_core/object.dart';

part 'standard_sync_payload.freezed.dart';
part 'standard_sync_payload.g.dart';

/// 标准请求体契约 (Cursor + Payloads)
abstract class StandardSyncRequestPart<P> {
  int get cursor;

  List<P> get payloads;

  Map<String, dynamic> toJson(Map<String, dynamic> Function(P) pToJson);
}

/// 通用请求体默认实现
@Freezed(genericArgumentFactories: true)
abstract class CommonSyncRequestPart<P>
    with _$CommonSyncRequestPart<P>
    implements StandardSyncRequestPart<P> {
  const factory CommonSyncRequestPart({
    required int cursor,
    @Default([]) List<P> payloads,
  }) = _CommonSyncRequestPart<P>;

  factory CommonSyncRequestPart.fromJson(
    Map<String, dynamic> json,
    P Function(Object?) fromJsonP,
  ) => _$CommonSyncRequestPartFromJson(json, fromJsonP);
}

/// 标准响应 ACK 契约
abstract class StandardSyncResponseAck {
  List<dynamic> get primaryId;
}

abstract class SyncRequestSnapshot {
  List<dynamic> get primaryId;
}

/// 标准响应体契约 (Acks + Payloads)
abstract class StandardSyncResponsePart<
  ACK extends StandardSyncResponseAck,
  P
> {
  List<ACK> get acks;

  List<P> get payloads;
}

@Freezed(genericArgumentFactories: true)
abstract class CommonSyncResponsePart<ACK extends StandardSyncResponseAck, P>
    with _$CommonSyncResponsePart<ACK, P>
    implements StandardSyncResponsePart<ACK, P> {
  const factory CommonSyncResponsePart({
    required List<ACK> acks,
    required List<P> payloads,
  }) = _CommonSyncResponsePart<ACK, P>;

  factory CommonSyncResponsePart.fromJson(
    Map<String, dynamic> json,

    ACK Function(Map<String, dynamic> json) fromJsonACK,
    P Function(Map<String, dynamic> json) fromJsonP,
  ) => _$CommonSyncResponsePartFromJson(
    json,
    (ack) => fromJsonACK(ack as Map<String, dynamic>),
    (e) => fromJsonP(e as Map<String, dynamic>),
  );
}
