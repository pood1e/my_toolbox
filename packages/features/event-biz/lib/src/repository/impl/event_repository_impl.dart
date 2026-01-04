import 'package:drift/drift.dart';
import 'package:event_api/event_api.dart';
import 'package:framework_api/framework_api.dart';

import '../../data/event_dao.dart';
import '../../data/event_database.dart';
import '../../data/event_mapper.dart';
import '../../data/event_table.dart';
import '../event_repository.dart';

class EventRepositoryImpl
    extends
        CoreSyncRepositoryBase<
          Event,
          EventEntity,
          Events,
          EventsCompanion,
          EventDao
        >
    implements EventRepository {
  EventRepositoryImpl({required super.dao, required super.timeService});

  @override
  Event Function(EventEntity) get toDomain =>
      (e) => e.toDomain();

  @override
  Future<Event> create({
    required String name,
    required String source,
    required int timestamp,
  }) async {
    final id = uuid.v4();
    final now = timeService.nowMs;

    final event = EventsCompanion.insert(
      id: id,
      name: name,
      timestamp: timestamp,
      source: source,
      createdAt: Value(now),
      updatedAt: now,
      isDirty: const Value(true),
    );

    final result = await dao.createIfNotExist(event);
    if (result == 0) {
      throw Exception();
    }
    return Event(id: id, name: name, timestamp: timestamp, source: source);
  }

  @override
  Future<Event> update(Event event) async {
    final now = timeService.nowMs;

    final companion = EventsCompanion(
      id: Value(event.id),
      name: Value(event.name),
      timestamp: Value(event.timestamp),
      source: Value(event.source),
      updatedAt: Value(now),
      isDirty: const Value(true),
    );

    final result = await dao.updateIfExist(companion);
    if (result == 0) {
      throw Exception();
    }
    return event;
  }

  @override
  Future<void> deleteByIdAndSource(String id, String source) async {
    final now = timeService.nowMs;
    await dao.softDeleteBySourceAndId(id, source, now);
  }

  @override
  Stream<List<Event>> watchByRange(int startTime, int endTime) {
    return dao
        .watchByRange(startTime, endTime) // 获取 Entity流
        .map((entities) => entities.map(toDomain).toList()); // 转换成 Model流
  }
}
