import 'package:app_core/object.dart';
import 'package:data_api/data_api.dart';

part 'sync_object.freezed.dart';
part 'sync_object.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class SyncDelta<T> with _$SyncDelta<T> {
  const factory SyncDelta({
    required int sequence,
    required String deviceId,
    required List<T> deltas,
  }) = _SyncDelta;

  factory SyncDelta.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$SyncDeltaFromJson(json, fromJsonT);
}

abstract class SyncObject {
  int get serverUpdatedAt;
}