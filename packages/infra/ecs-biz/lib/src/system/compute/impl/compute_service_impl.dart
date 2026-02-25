import '../../meta/property_meta_service.dart';
import '../compute_service.dart';
import 'compute_node.dart';
import 'compute_task.dart';

class ComputeServiceImpl implements ComputeService {
  final Map<String, Source> _sourceMap;
  final Map<String, Processor> _processorMap;
  final Map<String, Aggregator> _aggregatorMap;

  ComputeServiceImpl({
    required List<ReuseCompute> sources,
    required List<ReuseCompute> processors,
    required List<ReuseCompute> aggregators,
  }) : _sourceMap = {
         for (final source in sources) source.computeId: source as Source,
       },
       _processorMap = {
         for (final processor in processors)
           processor.computeId: processor as Processor,
       },
       _aggregatorMap = {
         for (final aggregator in aggregators)
           aggregator.computeId: aggregator as Aggregator,
       };

  @override
  Future<dynamic> compute(PropertyId self, List<ComputeMeta> metas) {
    if (metas.isEmpty) return Future.value(null);

    // 每次调用 compute 都实例化一个新的独立任务，确保多线程并发调用时状态不污染
    final task = ComputeTask(
      metas: metas,
      sourceMap: _sourceMap,
      processorMap: _processorMap,
      aggregatorMap: _aggregatorMap,
      self: self,
    );

    return task.run();
  }
}
