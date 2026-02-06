import '../../domain/property_descriptor.dart';
import '../../domain/type_descriptor.dart';
import '../value_types/simple_text_type.dart';

class NamePropertyDescriptor extends PropertyDescriptor<String, String>
    implements PropertyDefaultConfig<String> {
  @override
  String get propertyId => '_name';

  @override
  String get defaultConfig => 'unnamed';

  @override
  String get name => 'name';

  @override
  TypeDescriptor<String, String> get typeDescriptor =>
      SimpleTextTypeDescriptor();
}
