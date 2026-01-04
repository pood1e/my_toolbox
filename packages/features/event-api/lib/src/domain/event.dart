import 'package:app_core/object.dart';

part 'event.freezed.dart';

@freezed
abstract class Event with _$Event {
  const factory Event({
    required String id,
    required String name,
    required int timestamp,
    required String source
  }) = _Event;
}
