import '../../domain/stored_value.dart';
import '../../domain/type_descriptor.dart';
import '../config_converters/simple_config_converter.dart';
import '../converters/typed_json_converter.dart';
import '../value_converters/json_value_converter.dart';

class SimpleJsonType<C, T> implements TypeDescriptor<C, T> {
  final TypedJsonConverter<C> _jsonConfigConverter;
  final TypedJsonConverter<T> _jsonValueConverter;
  @override
  final ComputeEngine<C, T> engine;

  SimpleJsonType({
    required TypedJsonConverter<C> jsonConfigConverter,
    required TypedJsonConverter<T> jsonValueConverter,
    required this.engine,
  }) : _jsonConfigConverter = jsonConfigConverter,
       _jsonValueConverter = jsonValueConverter;

  @override
  ConfigConverter<C> get configConverter => SimpleConfigConverter<C>(
    converter: TypedStringConverter<C>(converter: _jsonConfigConverter),
  );

  @override
  StorageType get storageType => StorageType.json;

  @override
  ValueConverter<T> get valueConverter => JsonValueConverter<T>(
    converter: TypedStringConverter<T>(converter: _jsonValueConverter),
  );

  @override
  String get valueId => 'icon';
}
