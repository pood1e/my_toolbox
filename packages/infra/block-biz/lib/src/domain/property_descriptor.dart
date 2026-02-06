import '../service/evalutor.dart';
import 'property.dart';
import 'property_config.dart';

enum StorageType { bool, int, real, text, json }

abstract class PropertyContext {
  PropertyKey get propertyKey;

  Future<C> getConfig<C>(String? configKey);
}

/// T: 值类型
abstract class PropertyDescriptor<C, T> {
  String get defId;

  String get name;

  PropertyConfigDescriptor<C> get configDescriptor;

  // config -> value
  Evalutor<C, T> get evalutor;

  PropertyValueDescriptor<T> get valueDescriptor;
}

/// C: 配置
abstract class PropertyConfigDescriptor<C> {
  C decode(List<PropertyConfigRecord> records);

  List<PropertyConfigRecord> encode(C config);
}

/// T: 值类型
abstract class PropertyValueDescriptor<T> {
  StorageType get storageType;

  T decode(PropertyValue value);

  PropertyValue encode(T value);
}

/// 拥有默认值
abstract class PropertyDefaultConfig<C> {
  String get defId;

  C get defaultConfig;
}
