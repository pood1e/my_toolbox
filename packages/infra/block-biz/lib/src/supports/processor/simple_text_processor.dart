import '../../domain/compute_engine.dart';

class SimpleTextProcessor extends Processor<String, String> {
  @override
  String fromDb(dynamic value) => value.toString();

  @override
  String get id => 'simple_text';

  @override
  Future<String> process(String config) async => config;

  @override
  dynamic toDb(String value) => value;

  @override
  String get typeId => 'text';
}
