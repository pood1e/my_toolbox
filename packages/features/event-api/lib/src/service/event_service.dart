import '../domain/event.dart';

abstract class EventService {
  Future<Event> createEvent({
    required String name,
    required String source,
    required int timestamp,
  });

  Future<void> updateEvent({
    required String id,
    required String source,
    required String name,
    required int timestamp,
  });

  Future<void> deleteEvent({required String id, required String source});
}
