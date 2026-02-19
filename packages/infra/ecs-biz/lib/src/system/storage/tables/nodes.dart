import 'package:drift/drift.dart';

// insert only
@DataClassName('NodeEntity')
class Nodes extends Table {
  TextColumn get id => text()(); // NanoID

  @override
  Set<Column> get primaryKey => {id};
}
