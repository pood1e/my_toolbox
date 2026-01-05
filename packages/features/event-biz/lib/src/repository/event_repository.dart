import 'package:event_api/event_api.dart';
import 'package:framework_api/framework_api.dart';

import '../data/event_database.dart';

abstract class EventRepository {
  Stream<List<Event>> watchByRange(int startTime, int endTime);

  Future<Event> create({
    required String name,
    required String source,
    required int timestamp,
    required int nowMs
  });

  Future<void> update(Event e, int nowMs);

  Future<void> deleteByIdAndSource(String id, String source, int nowMs);
}
