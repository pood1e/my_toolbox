import 'package:event_api/event_api.dart';

import '../repository/event_repository.dart';

class EventServiceImpl implements EventService {
  final EventRepository _repository;

  EventServiceImpl({required EventRepository repository})
    : _repository = repository;

  @override
  Future<Event> createEvent({
    required String name,
    required String source,
    required int timestamp,
  }) {
    return _repository.create(name: name, source: source, timestamp: timestamp);
  }

  @override
  Future<void> deleteEvent({required String id, required String source}) {
    return _repository.deleteByIdAndSource(id, source);
  }

  @override
  Future<Event> updateEvent({
    required String id,
    required String source,
    required String name,
    required int timestamp,
  }) async {
    return await _repository.update(
      Event(id: id, name: name, timestamp: timestamp, source: source),
    );
  }
}
