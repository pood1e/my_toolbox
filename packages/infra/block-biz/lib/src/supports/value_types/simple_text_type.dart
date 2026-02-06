import '../../domain/stored_config.dart';
import '../../domain/stored_value.dart';
import '../../domain/type_descriptor.dart';
import '../compute_engines/direct_engine.dart';

class SimpleTextTypeDescriptor extends TypeDescriptor<String, String> {
  @override
  ConfigConverter<String> get configConverter => throw UnimplementedError();

  @override
  ComputeEngine<String, String> get engine => DirectEngine();

  @override
  StorageType get storageType => StorageType.text;

  @override
  ValueConverter<String> get valueConverter => SimpleTextValueConverter();

  @override
  String get valueId => 'simple_text';
}

class SimpleTextConfigConverter implements ConfigConverter<String> {
  @override
  List<StoredConfig> encode(String config) => [
    StoredConfig.simple(config: config),
  ];

  @override
  String decode(List<StoredConfig> records) => records.first.config!;
}

class SimpleTextValueConverter implements ValueConverter<String> {
  @override
  String decode(value) => value;

  @override
  encode(String value) => value;
}
