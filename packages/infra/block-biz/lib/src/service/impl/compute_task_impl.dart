import 'package:app_core/logger.dart';

import '../../domain/compute_engine.dart';
import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../../domain/property_definition.dart';
import '../../domain/stored_value.dart';
import '../../repository/property_compute_repository.dart';
import '../compute_task_scheduler.dart';

class ComputeTaskImpl implements ComputeTask {
  final ComputeContext _ctx;

  ComputeTaskImpl({required ComputeContext ctx}) : _ctx = ctx;

  @override
  Future<void> run() async {
    // 事务包裹计算逻辑
    final resultNormal = await _ctx.transcation(_compute);
    if (!resultNormal) {
      throw StructureChangedException();
    }
  }

  /// 核心计算流程
  Future<bool> _compute() async {
    // 1. 获取并解析配置 (假设 getConfig 返回的是解析好的 PropertyConfig Sealed Class)
    final config = await _ctx.getConfig();

    if (config == null) {
      logger.i('detect config removed');
      await _ctx.markDownstreamDirty();
      await _ctx.deleteProperty();
      return false;
    }

    try {
      // 2. 模式匹配执行 (利用 Freezed 的 map)
      final result = await config.map(
        singleStatic: _computeSingleStatic,
        singleRef: _computeSingleRef,
        multiStatic: _computeMultiStatic,
        multiRef: _computeMultiRef,
        hybrid: _computeHybrid,
      );

      // 3. 结果保存
      final dataTypeDefinition = _ctx.descriptor.dateType.definition;
      final property = NormalStoredValue(
        value: dataTypeDefinition.toDb(result),
        storageType: dataTypeDefinition.storageType,
      );
      await _ctx.saveProperty(property);
      return true;
    } on DependencyDirtyException {
      logger.i('detect dirty dependencies, skipping save');
      // 依赖脏了，调度器通常会重新调度，这里直接跳过
    } on DependencyErrorException {
      logger.i('detect error dependencies');
      await _ctx.markAsRefError();
    } catch (e, stack) {
      logger.e('detect compute error: $e', error: e, stackTrace: stack);
      await _ctx.markAsConfigError();
    }
    return false;
  }

  // ===========================================================================
  // 模式实现 (Mode Implementations)
  // ===========================================================================

  Future<dynamic> _computeSingleStatic(SingleStaticPropertyConfig config) =>
      _runProcessor(config.source);

  Future<dynamic> _computeSingleRef(SingleRefPropertyConfig config) async {
    final key = config.target;
    // 如果没有 target，视为 null 输入
    final property = key != null ? await _ctx.getProperty(key) : null;
    return _runTransformer(config.transformer, property);
  }

  Future<dynamic> _computeMultiStatic(MultiStaticPropertyConfig config) async {
    // 并行执行所有 Processor
    final entries = await Future.wait(
      config.sources.entries.map((e) async {
        final val = await _runProcessor(e.value);
        return MapEntry(e.key, val);
      }),
    );

    final inputMap = Map.fromEntries(entries);
    return _runAggregator(config.aggregator, inputMap);
  }

  Future<dynamic> _computeMultiRef(MultiRefPropertyConfig config) async {
    // 1. 批量获取 (Batch Fetch) - 解决 N+1
    final keysToFetch = config.sources.values
        .map((e) => e.target)
        .whereType<PropertyKey>()
        .toSet();

    final propertyMap = await _ctx.getProperties(keysToFetch);

    // 2. 并行转换 (Parallel Transform)
    final entries = await Future.wait(
      config.sources.entries.map((entry) async {
        final sourceKey = entry.key;
        final sourceConfig = entry.value;

        final prop = sourceConfig.target != null
            ? propertyMap[sourceConfig.target]
            : null;

        final val = await _runTransformer(sourceConfig.transformer, prop);
        return MapEntry(sourceKey, val);
      }),
    );

    // 3. 聚合
    return _runAggregator(config.aggregator, Map.fromEntries(entries));
  }

  Future<dynamic> _computeHybrid(HybridPropertyConfig config) async {
    // 1. Static 部分 (并行)
    final staticFuture = Future.wait(
      config.staticSources.entries.map(
        (e) async => MapEntry(e.key, await _runProcessor(e.value)),
      ),
    );

    // 2. Ref 部分 (批量获取 + 并行转换)
    final refFuture = (() async {
      final keysToFetch = config.refSources.values
          .map((e) => e.target)
          .whereType<PropertyKey>()
          .toSet();

      final propertyMap = await _ctx.getProperties(keysToFetch);

      return await Future.wait(
        config.refSources.entries.map((entry) async {
          final prop = entry.value.target != null
              ? propertyMap[entry.value.target]
              : null;
          final val = await _runTransformer(entry.value.transformer, prop);
          return MapEntry(entry.key, val);
        }),
      );
    })();

    // 3. 等待两者完成并合并
    final results = await Future.wait([staticFuture, refFuture]);
    final staticResults = results[0];
    final refResults = results[1];

    final mergedInput = {
      ...Map.fromEntries(staticResults),
      ...Map.fromEntries(refResults),
    };

    // 4. 聚合
    return _runAggregator(config.aggregator, mergedInput);
  }

  // ===========================================================================
  // 通用执行器 (Generic Executors) - 消除重复代码
  // ===========================================================================

  /// 执行 Processor (Static Source)
  Future<dynamic> _runProcessor(StaticSourceConfig config) async {
    final processor = _ctx.processorRegistry[config.processorId];
    if (processor == null) {
      throw ProcessorException();
    }

    dynamic cfg = processor.fromDb(config.raw);
    final msg = processor.validate(cfg);
    if (msg != null) {
      logger.e('processor config error: $msg');
      throw ProcessorException();
    }

    try {
      return await processor.process(cfg);
    } catch (e, s) {
      logger.e('processor execution error', error: e, stackTrace: s);
      throw ProcessorException();
    }
  }

  /// 执行 Transformer (Ref Source)
  Future<dynamic> _runTransformer(
    TransformerConfig config,
    Property? inputProperty,
  ) async {
    final transformer = _ctx.transformerRegistry[config.transformerId];
    if (transformer == null) {
      throw TransformerException();
    }

    dynamic cfg = transformer.fromDb(config.raw);
    final msg = transformer.validate(cfg);
    if (msg != null) {
      logger.e('transformer config error: $msg');
      throw TransformerException();
    }

    try {
      return await transformer.transform(inputProperty, cfg);
    } catch (e, s) {
      logger.e('transformer execution error', error: e, stackTrace: s);
      throw TransformerException();
    }
  }

  /// 执行 Aggregator
  Future<dynamic> _runAggregator(
    AggConfig config,
    Map<String, dynamic> inputs,
  ) async {
    final aggregator = _ctx.aggregatorRegistry[config.aggregatorId];
    if (aggregator == null) {
      throw AggregatorException();
    }

    dynamic cfg = aggregator.fromDb(config.raw);
    final msg = aggregator.validate(cfg);
    if (msg != null) {
      logger.e('aggregator config error: $msg');
      throw AggregatorException();
    }

    try {
      return await aggregator.aggregate(inputs, cfg);
    } catch (e, s) {
      logger.e('aggregator execution error', error: e, stackTrace: s);
      throw AggregatorException();
    }
  }
}

class ComputeContextImpl implements ComputeContext {
  final PropertyComputeRepository _repo;
  final Map<String, PropertyDescriptor> _descriptorMap;
  final PropertyKey _key;

  @override
  final Map<String, Aggregator> aggregatorRegistry;

  @override
  final Map<String, Processor> processorRegistry;

  @override
  final Map<String, Transformer> transformerRegistry;

  ComputeContextImpl({
    required PropertyComputeRepository repo,
    required Map<String, PropertyDescriptor> descriptorMap,
    required PropertyKey key,
    required this.aggregatorRegistry,
    required this.processorRegistry,
    required this.transformerRegistry,
  }) : _repo = repo,
       _descriptorMap = descriptorMap,
       _key = key;

  @override
  PropertyDescriptor get descriptor => _descriptorMap[_key.defId]!;

  @override
  Future<void> saveProperty(StoredValue value) =>
      _repo.saveProperty(Property(key: _key, value: value));

  @override
  Future<void> deleteProperty() async => await _repo.deleteProperty(_key);

  @override
  Future<PropertyConfig?> getConfig() async => await _repo.getConfig(_key);

  @override
  Future<void> markDownstreamDirty() =>
      _repo.markDirtyRecursive(rootKeys: {_key}, includeSelf: false);

  @override
  Future<void> markAsConfigError() => _repo.markErrorRecursive(
    rootKeys: {_key},
    rootError: ValueError.configInvalid,
  );

  @override
  Future<void> markAsRefError() => _repo.markErrorRecursive(
    rootKeys: {_key},
    rootError: ValueError.referenceInvalid,
  );

  @override
  Future<T> transcation<T>(Future<T> Function() action) =>
      _repo.transcation(action);

  @override
  Future<Map<PropertyKey, Property>> getProperties(
    Set<PropertyKey> keys,
  ) async {
    final keyMap = {
      for (final key in keys)
        key: _descriptorMap[key.defId]!.dateType.definition,
    };
    return await _repo.getProperties(keyMap);
  }

  @override
  Future<Property?> getProperty(PropertyKey key) async {
    final result = await getProperties({key});
    return result[key];
  }
}

class ComputeTaskFactoryImpl implements ComputeTaskFactory {
  final Map<String, PropertyDescriptor> _descriptorMap;
  final PropertyComputeRepository _repo;
  final Map<String, Aggregator> _aggregatorRegistry;

  final Map<String, Processor> _processorRegistry;

  final Map<String, Transformer> _transformerRegistry;

  ComputeTaskFactoryImpl({
    required Map<String, PropertyDescriptor> descriptorMap,
    required PropertyComputeRepository repo,
    required Map<String, Aggregator> aggregatorRegistry,
    required Map<String, Processor> processorRegistry,
    required Map<String, Transformer> transformerRegistry,
  }) : _descriptorMap = descriptorMap,
       _repo = repo,
       _aggregatorRegistry = aggregatorRegistry,
       _processorRegistry = processorRegistry,
       _transformerRegistry = transformerRegistry;

  @override
  ComputeTask create(PropertyKey key) {
    logger.d('create compute task @$key');
    return ComputeTaskImpl(
      ctx: ComputeContextImpl(
        repo: _repo,
        key: key,
        descriptorMap: _descriptorMap,
        aggregatorRegistry: _aggregatorRegistry,
        processorRegistry: _processorRegistry,
        transformerRegistry: _transformerRegistry,
      ),
    );
  }
}
