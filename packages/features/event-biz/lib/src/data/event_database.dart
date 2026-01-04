import 'package:drift/drift.dart';

import 'event_table.dart';

part 'event_database.g.dart';

@DriftDatabase(tables: [Events])
class EventDatabase extends _$EventDatabase {
  EventDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
