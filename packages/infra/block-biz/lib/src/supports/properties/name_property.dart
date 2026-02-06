import '../../domain/property_descriptor.dart';
import '../../domain/type_descriptor.dart';
import '../value_types/simple_text_type.dart';

class NameProperty extends PropertyDescriptor<String, String> {
  @override
  String get propertyId => '_name';

  @override
  TypeDescriptor<String, String> get typeDescriptor =>
      SimpleTextTypeDescriptor();
}
