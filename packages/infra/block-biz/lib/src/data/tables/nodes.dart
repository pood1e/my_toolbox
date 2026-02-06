import 'package:drift/drift.dart';

@DataClassName('NodeEntity')
class Nodes extends Table {
  TextColumn get id => text()(); // NanoID

  @override
  Set<Column> get primaryKey => {id};
}
