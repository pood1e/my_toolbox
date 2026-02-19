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
      // 这里的异常通常触发外部重试或状态重置
      throw StructureChangedException();
    }
  }

  /// 核心计算流程
  Future<bool> _compute() async {
    // 1. 获取并解析配置
    // 注意：getConfig 返回的配置中，component 已经是实例，raw 已经是解析后的对象
    final config = await _ctx.getConfig();

    if (config == null) {
      logger.i('detect config removed');
      await _ctx.markDownstreamDirty();
      await _ctx.deleteProperty();
      return false;
    }

    try {
      // 2. 模式匹配执行
      // result 是业务值 (int, string, etc.)
      final result = await config.body.map(
        singleStatic: (c) => _runProcessor(c.processor),
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
      // 上游脏了，当前节点保持原样或标记为脏，等待重新调度
      logger.d('detect dirty dependencies, skipping save');
      // 可以在此处显式抛出中断，或返回 false，取决于调度器逻辑
    } on DependencyErrorException {
      logger.w('detect error dependencies');
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

  Future<dynamic> _computeSingleRef(SingleRefPropertyConfig config) async {
    final inputVal = await _resolveInput(config.transformer.target);
    return _runTransformer(config.transformer, inputVal);
  }

  Future<dynamic> _computeMultiStatic(MultiStaticPropertyConfig config) async {
    // 1. 并行执行 Processor
    final inputs = await Future.wait(
      config.processorMap.entries.map((e) async {
        final val = await _runProcessor(e.value);
        return MapEntry(e.key, val);
      }),
    );

    // 2. 聚合
    return _runAggregator(config.aggregator, Map.fromEntries(inputs));
  }

  Future<dynamic> _computeMultiRef(MultiRefPropertyConfig config) async {
    // 1. 批量获取依赖
    final propertyMap = await _fetchDependencies(config.transformerMap.values);

    // 2. 并行转换
    final inputs = await Future.wait(
      config.transformerMap.entries.map((entry) async {
        final component = entry.value;
        // 解包 Property -> Value
        final rawInput = _unwrapValue(propertyMap[component.target]);
        final val = await _runTransformer(component, rawInput);
        return MapEntry(entry.key, val);
      }),
    );

    // 3. 聚合
    return _runAggregator(config.aggregator, Map.fromEntries(inputs));
  }

  Future<dynamic> _computeHybrid(HybridPropertyConfig config) async {
    // 1. Static 部分 (并行)
    final staticFuture = Future.wait(
      config.processorMap.entries.map(
        (e) async => MapEntry(e.key, await _runProcessor(e.value)),
      ),
    );

    // 2. Ref 部分 (批量获取 + 并行转换)
    final refFuture = (() async {
      final propertyMap = await _fetchDependencies(
        config.transformerMap.values,
      );

      return await Future.wait(
        config.transformerMap.entries.map((entry) async {
          final component = entry.value;
          final rawInput = _unwrapValue(propertyMap[component.target]);
          final val = await _runTransformer(component, rawInput);
          return MapEntry(entry.key, val);
        }),
      );
    })();

    // 3. 合并结果
    final results = await Future.wait([staticFuture, refFuture]);

    final mergedInput = {
      ...Map.fromEntries(results[0]),
      ...Map.fromEntries(results[1]),
    };

    // 4. 聚合
    return _runAggregator(config.aggregator, mergedInput);
  }

  // ===========================================================================
  // 辅助方法 (Helpers)
  // ===========================================================================

  /// 批量获取依赖属性
  Future<Map<PropertyKey, Property>> _fetchDependencies(
    Iterable<TransformerComponent> components,
  ) async {
    final keys = components
        .map((c) => c.target)
        .whereType<PropertyKey>()
        .toSet();

    if (keys.isEmpty) return {};
    return await _ctx.getProperties(keys);
  }

  /// 获取单个依赖值 (包含解包逻辑)
  Future<dynamic> _resolveInput(PropertyKey? key) async {
    if (key == null) return null;
    final prop = await _ctx.getProperty(key);
    return _unwrapValue(prop);
  }

  /// 解包 StoredValue -> 真实业务值
  /// 并处理依赖状态异常
  dynamic _unwrapValue(Property? property) {
    if (property == null) return null;

    return switch (property.value) {
      NormalStoredValue(value: var v) => v, // 返回解码后的值
      DirtyStoredValue() => throw DependencyDirtyException(),
      ErrorStoredValue() => throw DependencyErrorException(),
    };
  }

  // ===========================================================================
  // 组件执行器 (Component Executors)
  // ===========================================================================

  Future<dynamic> _runProcessor(ProcessorComponent pc) async {
    // 校验 (如果 parse 阶段已经校验过，这里可以省略，或者作为双重保险)
    final error = pc.component.validate(pc.raw);
    if (error != null) {
      logger.w('Processor validation failed: $error');
      throw ProcessorException();
    }

    try {
      // 泛型 T 由 Processor 定义
      return await pc.component.process(pc.raw);
    } catch (e) {
      // 包装未知异常
      if (e is ComputeException) rethrow;
      throw ProcessorException();
    }
  }

  Future<dynamic> _runTransformer(
    TransformerComponent tc,
    dynamic sourceValue,
  ) async {
    final error = tc.component.validate(tc.raw);
    if (error != null) {
      logger.w('Transformer validation failed: $error');
      throw TransformerException();
    }

    try {
      // transform(S source, C config)
      return await tc.component.transform(
        _ctx.descriptor.dateType.definition.fromDb(sourceValue),
        tc.raw,
      );
    } catch (e) {
      if (e is ComputeException) rethrow;
      throw TransformerException();
    }
  }

  Future<dynamic> _runAggregator(
    AggregateComponent ac,
    Map<String, dynamic> inputs,
  ) async {
    final error = ac.component.validate(ac.raw);
    if (error != null) {
      logger.w('Aggregator validation failed: $error');
      throw AggregatorException();
    }

    try {
      return await ac.component.aggregate(inputs, ac.raw);
    } catch (e) {
      if (e is ComputeException) rethrow;
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
