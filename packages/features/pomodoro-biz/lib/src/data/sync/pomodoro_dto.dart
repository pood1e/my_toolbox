import 'package:app_core/object.dart';
import 'package:framework_api/framework_api.dart';

import '../../pomodoro_domain.dart';

part 'pomodoro_dto.freezed.dart';
part 'pomodoro_dto.g.dart';

@freezed
abstract class PomodoroSessionDto
    with _$PomodoroSessionDto
    implements LwwPayload {
  const PomodoroSessionDto._();

  const factory PomodoroSessionDto({
    required String id,
    required String name,
    String? note,
    required bool manualClosed,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _PomodoroSessionDto;

  factory PomodoroSessionDto.fromJson(Map<String, dynamic> json) =>
      _$PomodoroSessionDtoFromJson(json);

  @override
  List<dynamic> get primaryId => [id];
}

@freezed
abstract class PomodoroDto with _$PomodoroDto implements LwwPayload {
  const PomodoroDto._();

  const factory PomodoroDto({
    required String id,
    required String sessionId,
    required int startAt,
    required int endAt,
    required PomodoroType type,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _PomodoroDto;

  factory PomodoroDto.fromJson(Map<String, dynamic> json) =>
      _$PomodoroDtoFromJson(json);

  @override
  List<dynamic> get primaryId => [id];
}
