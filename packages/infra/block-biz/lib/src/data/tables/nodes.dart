import 'package:drift/drift.dart';

@DataClassName('NodeEntity')
class Nodes extends Table {
  TextColumn get id => text()(); // NanoID

  // Local fields
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
