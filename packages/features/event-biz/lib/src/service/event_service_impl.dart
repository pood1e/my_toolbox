import 'package:event_api/event_api.dart';
import 'package:framework_api/framework_api.dart';

import '../repository/event_repository.dart';

class EventServiceImpl implements EventService {
  final EventRepository _repository;
  final ServerTimeService _serverTimeService;

  EventServiceImpl({
    required EventRepository repository,
    required ServerTimeService serverTimeService,
  }) : _repository = repository,
       _serverTimeService = serverTimeService;

  @override
  Future<Event> createEvent({
    required String name,
    required String source,
    required int timestamp,
  }) {
    return _repository.create(
      name: name,
      source: source,
      timestamp: timestamp,
      nowMs: _serverTimeService.nowMs,
    );
  }

  @override
  Future<void> deleteEvent({required String id, required String source}) {
    return _repository.deleteByIdAndSource(id, source, _serverTimeService.nowMs);
  }

  @override
  Future<void> updateEvent({
    required String id,
    required String source,
    required String name,
    required int timestamp,
  }) async {
    return await _repository.update(
      Event(id: id, name: name, timestamp: timestamp, source: source),
      _serverTimeService.nowMs,
    );
  }
}
