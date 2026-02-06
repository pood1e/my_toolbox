import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../../domain/property_descriptor.dart';
import '../../service/evalutor.dart';
import '../../service/impl/direct_evalutor.dart';

class NamePropertyDescriptor extends PropertyDescriptor<String, String>
    implements PropertyDefaultConfig<String> {
  @override
  String get defId => '_name';

  @override
  String get defaultConfig => 'unnamed';

  @override
  PropertyConfigDescriptor<String> get configDescriptor =>
      NameConfigDescriptor();

  @override
  Evalutor<String, String> get evalutor => DirectEvalutor();

  @override
  String get name => 'name';

  @override
  PropertyValueDescriptor<String> get valueDescriptor =>
      NameValueDescriptor();
}

class NameConfigDescriptor implements PropertyConfigDescriptor<String> {
  @override
  String decode(List<PropertyConfigRecord> records) {
    return records.first.config as String;
  }

  @override
  List<PropertyConfigRecord> encode(String config) {
    return [PropertyConfigRecord(config: config)];
  }
}

class NameValueDescriptor implements PropertyValueDescriptor<String> {
  @override
  StorageType get storageType => StorageType.text;

  @override
  String decode(PropertyValue value) {
    if (value is SuccessPropertyValue) {
      return value.value;
    }
    throw Exception();
  }

  @override
  PropertyValue encode(String value) {
    return PropertyValue.success(value: value);
  }
}
