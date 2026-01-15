import 'package:app_core/uuid.dart';
import 'package:drift/drift.dart';
import 'package:event_api/event_api.dart';

import '../../data/event_dao.dart';
import '../../data/event_database.dart';
import '../../data/event_mapper.dart';
import '../event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final EventDao _dao;

  EventRepositoryImpl({required EventDao dao}) : _dao = dao;

  @override
  Future<Event> create({
    required String name,
    required String source,
    required int timestamp,
    required int nowMs,
  }) async {
    final id = Uuid().v4();

    final event = EventsCompanion.insert(
      id: id,
      name: name,
      timestamp: timestamp,
      source: source,
      createdAt: Value(nowMs),
      updatedAt: nowMs,
      isDirty: const Value(true),
    );

    final result = await _dao.createIfNotExist(event);
    if (!result) {
      throw Exception();
    }
    return Event(id: id, name: name, timestamp: timestamp, source: source);
  }

  @override
  Future<void> update(Event event, int nowMs) async {
    final companion = EventsCompanion(
      name: Value(event.name),
      timestamp: Value(event.timestamp),
      updatedAt: Value(nowMs),
      isDirty: const Value(true),
    );

    final result = await _dao.updateIfExist([event.id, event.source], companion);
    if (!result) {
      throw Exception();
    }
  }

  @override
  Future<void> deleteByIdAndSource(String id, String source, int nowMs) async {
    await _dao.softDelete([id, source], nowMs);
  }

  @override
  Stream<List<Event>> watchByRange(int startTime, int endTime) {
    return _dao
        .watchByRange(startTime, endTime)
        .map((entities) => entities.map((e) => e.toDomain()).toList());
  }
}
