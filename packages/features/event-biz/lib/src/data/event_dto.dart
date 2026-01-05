import 'package:app_core/object.dart';
import 'package:framework_api/framework_api.dart';

part 'event_dto.freezed.dart';
part 'event_dto.g.dart';

@freezed
abstract class EventDto with _$EventDto implements LwwObject {
  const EventDto._();

  const factory EventDto({
    required String id,
    required String name,
    required int timestamp,
    required String source,

    // Sync Meta
    required int createdAt,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _EventDto;

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  @override
  List<dynamic> get primaryKey => [id, source];
}

@freezed
abstract class EventAck with _$EventAck implements LwwAck {
  const EventAck._();

  const factory EventAck({
    required String id,
    required String source,
    required int serverUpdatedAt,
  }) = _EventAck;

  factory EventAck.fromJson(Map<String, dynamic> json) =>
      _$EventAckFromJson(json);

  @override
  List<dynamic> get primaryKey => [id, source];
}
