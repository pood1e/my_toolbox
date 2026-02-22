import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../meta/property_meta_service.dart';
import '../meta/registry/name_meta.dart';
import '../value/value_service.dart';
import 'impl/compute_service_impl.dart';

part 'compute_service.freezed.dart';
part 'compute_service.g.dart';

enum ComputeType { source, processor, aggregator }

enum ComputeError {
  valueInvalid,
  configInvalid,
  referenceInvalid,
  cycleDependencies,
}

@freezed
abstract class ComputeMeta with _$ComputeMeta {
  const factory ComputeMeta({
    required String computeId,
    required ComputeType type,
    dynamic config,
    String? nextId,
    ComputeType? nextType,
  }) = _ComputeMeta;
}

mixin PropertyComputeMeta<C> on PropertyValueMeta {
  List<ComputeMeta> buildComputeGraph(C cfg);
}

abstract class ComputeService {
  Future<dynamic> compute(List<ComputeMeta> metas);
}

class ComputeException implements Exception {
  final ComputeError error;

  ComputeException({required this.error});
}

@riverpod
Future<ComputeService> computeService(Ref ref) async => ComputeServiceImpl(
  sources: [NameConfigSource()],
  processors: [],
  aggregators: [],
);
