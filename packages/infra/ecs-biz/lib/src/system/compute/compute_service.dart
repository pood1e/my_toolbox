import '../meta/property_meta_service.dart';

enum ComputeType { source, processor, aggregator }

enum ComputeError {
  valueInvalid,
  configInvalid,
  referenceInvalid,
  cycleDependencies,
}

abstract class ComputeMeta {
  String get computeId;

  ComputeType get type;

  dynamic get config;

  String? get nextId;

  ComputeType? get nextType;
}

mixin PropertyComputeMeta on PropertyMeta {
  List<ComputeMeta> buildComputeGraph(dynamic cfg);
}

abstract class ComputeService {
  Future<dynamic> compute(List<ComputeMeta> metas);
}

class ComputeException implements Exception {
  final ComputeError error;

  ComputeException({required this.error});
}

// todo: inject
