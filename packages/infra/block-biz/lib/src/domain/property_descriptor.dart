import 'type_descriptor.dart';

/// property -> valueType
/// valueType hardcode
/// property expanded
abstract class PropertyDescriptor<C, T> {
  /// unique
  String get propertyId;

  TypeDescriptor<C, T> get typeDescriptor;
}
