import '../../domain/stored_value.dart';
import '../../domain/type_descriptor.dart';
import '../compute_engines/direct_engine.dart';
import '../config_converters/simple_config_converter.dart';
import '../converters/string_converter.dart';
import '../value_converters/direct_value_converter.dart';

class SimpleTextTypeDescriptor extends TypeDescriptor<String, String> {
  @override
  ConfigConverter<String> get configConverter =>
      SimpleConfigConverter<String>(converter: SimpleStringConverter());

  @override
  ComputeEngine<String, String> get engine => DirectEngine<String>();

  @override
  StorageType get storageType => StorageType.text;

  @override
  ValueConverter<String> get valueConverter => DirectValueConverter();

  @override
  String get valueId => 'simple_text';
}
