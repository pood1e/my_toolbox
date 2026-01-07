import 'package:app_core/object.dart';

part 'delta_payload.freezed.dart';
part 'delta_payload.g.dart';

class DeltaStateSnapshot {
  final bool hasUnsync; // 是否有待发送的数据
  final bool hasLocked; // 是否有正在发送(未确认)的数据

  DeltaStateSnapshot({required this.hasUnsync, required this.hasLocked});
}

/// Delta 同步请求体
@Freezed(genericArgumentFactories: true)
abstract class DeltaSyncRequestPart<T> with _$DeltaSyncRequestPart<T> {
  const factory DeltaSyncRequestPart({
    required int sequence,
    required String deviceId,
    required List<T> deltas,
  }) = _DeltaSyncRequestPart<T>;

  factory DeltaSyncRequestPart.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$DeltaSyncRequestPartFromJson(json, fromJsonT);
}
