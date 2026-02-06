import 'package:app_core/logger.dart';

import '../../data/daos/compute_property_dao.dart';
import '../../data/mappers.dart';
import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../../domain/property_descriptor.dart';
import '../compute_task_scheduler.dart';
import '../evalutor.dart';

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
      final propertyConfig = await _ctx.getConfig();
      if (propertyConfig == null) {
        throw NoConfigException();
      }
      final actualConfig = _ctx.descriptor.configDescriptor.decode(
        propertyConfig.records,
      );
      dynamic result = await _ctx.descriptor.evalutor.eval(
        _ctx.evalutorContext,
        actualConfig,
      );
      final property = _ctx.descriptor.valueDescriptor.encode(result);
      await _ctx.saveProperty(property);
      return true;
    } on DependencyDirtyException {
      // 按照正常调度应该不会进入该逻辑中
      // 应该重新构建局部依赖图了
    } on DependencyErrorException {
      await _ctx.markAsRefError();
    } on NoConfigException {
      await _ctx.markDownstreamDirty();
      await _ctx.deleteProperty();
    } catch (e) {
      await _ctx.markAsConfigError();
    }
    return false;
  }
}

class ComputeContextImpl implements ComputeContext {
  final ComputePropertyDao _dao;
  final PropertyKey _key;
  @override
  final PropertyDescriptor descriptor;

  @override
  final EvalutorContext evalutorContext;

  ComputeContextImpl({
    required ComputePropertyDao dao,
    required PropertyKey key,
    required this.descriptor,
    required this.evalutorContext,
  }) : _dao = dao,
       _key = key;

  @override
  Future<void> saveProperty(PropertyValue value) async {
    await _dao.saveProperty(
      Property(
        key: PropertyStorageKey(
          nodeId: _key.nodeId,
          defId: _key.defId,
          type: descriptor.valueDescriptor.storageType,
        ),
        value: value,
      ).toCompanion(),
    );
  }

  @override
  Future<void> deleteProperty() async {
    await _dao.deleteProperty(_key);
  }

  @override
  Future<PropertyConfig?> getConfig() async {
    final result = await _dao.getConfig(_key);
    if (result.isEmpty) {
      return null;
    }
    return result.toDomain(_key);
  }

  @override
  Future<void> markDownstreamDirty() async {
    await _dao.markOnlyDownstreamDirty({_key});
  }

  @override
  Future<void> markAsConfigError() async {
    await _dao.markAsConfigError({_key});
  }

  @override
  Future<void> markAsRefError() async {
    await _dao.markAsRefError({_key});
  }

  @override
  Future<T> transcation<T>(Future<T> Function() action) {
    return _dao.transaction(action);
  }
}

class ComputeTaskFactoryImpl implements ComputeTaskFactory {
  final Map<String, PropertyDescriptor> _descriptorMap;
  final ComputePropertyDao _dao;
  final EvalutorContext _evalutorContext;

  ComputeTaskFactoryImpl({
    required Map<String, PropertyDescriptor> descriptorMap,
    required ComputePropertyDao dao,
    required EvalutorContext evalutorContext,
  }) : _descriptorMap = descriptorMap,
       _dao = dao,
       _evalutorContext = evalutorContext;

  @override
  ComputeTask create(PropertyKey key) {
    logger.d('create compute task @$key');
    return ComputeTaskImpl(
      ctx: ComputeContextImpl(
        dao: _dao,
        key: key,
        descriptor: _descriptorMap[key.defId]!,
        evalutorContext: _evalutorContext,
      ),
    );
  }
}
