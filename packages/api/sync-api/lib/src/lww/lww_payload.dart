import 'package:app_core/object.dart';

import 'lww_models.dart';

part 'lww_payload.freezed.dart';
part 'lww_payload.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class LwwResponsePayload<T, ACK extends LwwAck>
    with _$LwwResponsePayload<T, ACK> {
  const factory LwwResponsePayload({
    required List<ACK> acks,
    required List<T> changes,
  }) = _LwwResponsePayload<T, ACK>;

  factory LwwResponsePayload.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
    ACK Function(Map<String, dynamic> json) fromJsonACK,
  ) => _$LwwResponsePayloadFromJson(
    json,
    (e) => fromJsonT(e as Map<String, dynamic>),
    (ack) => fromJsonACK(ack as Map<String, dynamic>),
  );
}

@Freezed(genericArgumentFactories: true)
abstract class LwwRequestPayload<T> with _$LwwRequestPayload<T> {
  const factory LwwRequestPayload({
    required int cursor,
    required List<T> changes,
  }) = _LwwRequestPayload<T>;

  factory LwwRequestPayload.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) => _$LwwRequestPayloadFromJson(
    json,
    (e) => fromJsonT(e as Map<String, dynamic>),
  );
}
