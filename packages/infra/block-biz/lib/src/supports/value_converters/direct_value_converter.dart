import '../../domain/type_descriptor.dart';

class DirectValueConverter<T> implements ValueConverter<T> {
  @override
  T decode(value) => value;

  @override
  encode(T value) => value;
}
