import '../value_service.dart';

class SimpleText implements DataType<String> {
  @override
  String? fromDb(value) => value;

  @override
  String get id => 'simple_text';

  @override
  toDb(String value) => value;
}
