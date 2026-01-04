import 'package:app_core/object.dart';

part 'event_dto.freezed.dart';
part 'event_dto.g.dart';

@freezed
abstract class EventDto with _$EventDto {
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
}
