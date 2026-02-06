import 'package:app_core/logger.dart';

import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../../domain/property_descriptor.dart';
import '../../domain/stored_value.dart';
import '../../domain/type_descriptor.dart';
import '../../repository/property_compute_repository.dart';
import '../compute_engine_context.dart';
import '../compute_task_scheduler.dart';

class ComputeTaskImpl implements ComputeTask {
  final ComputeContext _ctx;

  ComputeTaskImpl({required ComputeContext ctx}) : _ctx = ctx;

  @override
  Future<void> run() async {
    final resultNormal = await _ctx.transcation(_compute);
    if (!resultNormal) {
      throw StructureChangedException();
    }
  }

  Future<bool> _compute() async {
    try {
      final config = await _ctx.getConfig();
      if (config == null) {
        throw NoConfigException();
      }
      final actualConfig = _ctx.descriptor.configConverter.decode(
        config.configs,
      );
      dynamic result = await _ctx.descriptor.engine.compute(actualConfig);
      final property = NormalStoredValue(
        value: _ctx.descriptor.valueConverter.encode(result),
        storageType: _ctx.descriptor.storageType,
      );
      await _ctx.saveProperty(property);
      return true;
    } on DependencyDirtyException {
      logger.i('detect dirty dependencies');
      // 按照正常调度应该不会进入该逻辑中
      // 应该重新构建局部依赖图了
    } on DependencyErrorException {
      logger.i('detect error dependencies');
      await _ctx.markAsRefError();
    } on NoConfigException {
      logger.i('detect config removed');
      await _ctx.markDownstreamDirty();
      await _ctx.deleteProperty();
    } catch (e, stack) {
      logger.i(
        'detect compute error: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      await _ctx.markAsConfigError();
    }
    return false;
  }
}

class ComputeContextImpl implements ComputeContext {
  final PropertyComputeRepository _repo;
  final PropertyKey _key;
  @override
  final TypeDescriptor descriptor;

  @override
  final ComputeEngineContext engineCtx;

  ComputeContextImpl({
    required PropertyComputeRepository repo,
    required PropertyKey key,
    required this.descriptor,
    required this.engineCtx,
  }) : _repo = repo,
       _key = key;

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
}

class ComputeTaskFactoryImpl implements ComputeTaskFactory {
  final Map<String, PropertyDescriptor> _descriptorMap;
  final PropertyComputeRepository _repo;
  final ComputeEngineContext _engineCtx;

  ComputeTaskFactoryImpl({
    required Map<String, PropertyDescriptor> descriptorMap,
    required PropertyComputeRepository repo,
    required ComputeEngineContext engineCtx,
  }) : _descriptorMap = descriptorMap,
       _repo = repo,
       _engineCtx = engineCtx;

  @override
  ComputeTask create(PropertyKey key) {
    logger.d('create compute task @$key');
    return ComputeTaskImpl(
      ctx: ComputeContextImpl(
        repo: _repo,
        key: key,
        descriptor: _descriptorMap[key.defId]!.typeDescriptor,
        engineCtx: _engineCtx,
      ),
    );
  }
}
