import 'package:app_core/di.dart';

import '../../domain/compute_engine.dart';
import '../processor/simple_icon_processor.dart';
import '../processor/simple_text_processor.dart';

part 'compute_engine_registry.g.dart';

@Riverpod(keepAlive: true)
List<Processor> processors(Ref ref) => [
  SimpleTextProcessor(),
  SimpleIconProcessor(),
];

@riverpod
Map<String, Processor> processorRegistry(Ref ref) {
  final processors = ref.read(processorsProvider);
  return {for (final p in processors) p.id: p};
}

@riverpod
Processor? processor(Ref ref, String id) =>
    ref.read(processorRegistryProvider)[id];

@Riverpod(keepAlive: true)
List<Transformer> transformers(Ref ref) => [];

@riverpod
Map<String, Transformer> transformerRegistry(Ref ref) {
  final transformers = ref.read(transformersProvider);
  return {for (final p in transformers) p.id: p};
}

@riverpod
Transformer? transformer(Ref ref, String id) =>
    ref.read(transformerRegistryProvider)[id];

@Riverpod(keepAlive: true)
List<Aggregator> aggregators(Ref ref) => [];

@riverpod
Map<String, Aggregator> aggregatorRegistry(Ref ref) {
  final aggregators = ref.read(aggregatorsProvider);
  return {for (final p in aggregators) p.id: p};
}

@riverpod
Aggregator? aggregator(Ref ref, String id) =>
    ref.read(aggregatorRegistryProvider)[id];
