import '../../domain/stored_config.dart';
import '../../domain/type_descriptor.dart';
import '../converters/string_converter.dart';

class SimpleConfigConverter<C> implements ConfigConverter<C> {
  final StringConverter<C> _converter;

  SimpleConfigConverter({required StringConverter<C> converter})
    : _converter = converter;

  @override
  C decode(List<StoredConfig> records) =>
      _converter.decode(records.first.config!);

  @override
  List<StoredConfig> encode(C config) => [
    StoredConfig.simple(config: _converter.encode(config)!),
  ];
}
