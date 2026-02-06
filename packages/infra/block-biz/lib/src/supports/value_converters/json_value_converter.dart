import '../../domain/type_descriptor.dart';
import '../converters/typed_json_converter.dart';

class JsonValueConverter<T> extends ValueConverter<T> {
  final TypedStringConverter<T> _converter;

  JsonValueConverter({required TypedStringConverter<T> converter})
    : _converter = converter;

  @override
  T decode(value) => _converter.decode(value);

  @override
  encode(T value) => _converter.encode(value);
}
