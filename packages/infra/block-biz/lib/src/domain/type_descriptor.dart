import 'stored_config.dart';
import 'stored_value.dart';

/// 类型描述符
/// property 必须指定一个 type
/// 一般来说运行时值和配置是强相关的
abstract class TypeDescriptor<C, T> {
  String get valueId;

  // stored-config <-> runtime config
  ConfigConverter<C> get configConverter;

  // stored-value <-> runtime value
  ValueConverter<T> get valueConverter;

  StorageType get storageType;

  ComputeEngine<C, T> get engine;
}

/// 运行时配置 <-> 存储配置
/// C: 运行时配置类型
abstract class ConfigConverter<C> {
  C decode(List<StoredConfig> records);

  List<StoredConfig> encode(C config);
}

class ConfigConvertException implements Exception {}

/// 运行时值 <-> 存储值
/// T: 值类型
abstract class ValueConverter<T> {
  T decode(dynamic value);

  dynamic encode(T value);
}

class ValueConvertException implements Exception {}

/// 计算引擎
/// 从配置到值的计算
abstract class ComputeEngine<C, T> {
  Future<T> compute(C config);
}
