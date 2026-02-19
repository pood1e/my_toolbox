abstract class Source<C, T> {
  String get computeId;

  Future<T> create(C config);
}

abstract class Processor<S, C, T> {
  String get computeId;

  Future<T> process(S source, C config);
}

abstract class Aggregator<C, T> {
  String get computeId;

  Future<T> aggregate(Map<String, dynamic> sMap, C config);
}
