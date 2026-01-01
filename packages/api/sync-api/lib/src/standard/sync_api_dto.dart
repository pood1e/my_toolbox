import 'package:app_core/object.dart';

part 'sync_api_dto.freezed.dart';
part 'sync_api_dto.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class SyncRequest<T> with _$SyncRequest<T> {
  const SyncRequest._();

  const factory SyncRequest({int? cursor, T? payload}) = _SyncRequest;

  factory SyncRequest.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$SyncRequestFromJson(json, fromJsonT);
}