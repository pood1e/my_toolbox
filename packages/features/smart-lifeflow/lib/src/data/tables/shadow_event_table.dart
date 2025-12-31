import 'package:drift/drift.dart';

class ShadowEvents extends Table {
  TextColumn get id => text()();

  TextColumn get type => text()(); // 'gps', 'app', 'health'
  TextColumn get rawData => text()(); // JSON
  IntColumn get detectedAt => integer()();

  IntColumn get status =>
      integer().withDefault(const Constant(0))(); // 0:Pending, 1:Converted

  @override
  Set<Column> get primaryKey => {id};
}
