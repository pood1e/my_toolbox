// 基础配置接口


abstract class Configurable<C> {
  String get id;

  C fromDb(dynamic value);

  dynamic toDb(C value);

  String? validate(C config) => null;
}

abstract class Processor<C, T> extends Configurable<C> {
  String get typeId;

  Future<T> process(C config);
}

abstract class Transformer<S, C, T> extends Configurable<C> {
  String get sTypeId;

  String get tTypeId;

  Future<T> transform(S source, C config);
}

abstract class Aggregator<C, T> extends Configurable<C> {

  String get tTypeId;

  Future<T> aggregate(Map<String, dynamic> sMap, C config);
}

sealed class ComputeException implements Exception {}

class ProcessorException extends ComputeException {}

class TransformerException extends ComputeException {}

class DependencyDirtyException extends TransformerException {}

class DependencyErrorException extends TransformerException {}

class AggregatorException extends ComputeException {}
