import 'compute_engine.dart';
import 'stored_value.dart';

/// 定义一种业务数据类型
abstract class DataTypeDefinition<T> {
  // 唯一标识 (如 'color', 'int', 'json_obj')
  String get id;

  // 对应的物理存储类型
  StorageType get storageType;

  // 编解码逻辑 (Codec)
  T fromDb(dynamic value);

  dynamic toDb(T value);
}

// runtime
class DataType<T> {
  final String id;
  final DataTypeDefinition<T> definition;

  final Set<Processor> processors;
  final Set<Transformer> transformers;
  final Set<Aggregator> aggregators;

  Set<String> get supportRefTypes =>
      transformers.map((trans) => trans.sTypeId).toSet();

  DataType({
    required this.id,
    required this.definition,
    required this.processors,
    required this.transformers,
    required this.aggregators,
  });
}
