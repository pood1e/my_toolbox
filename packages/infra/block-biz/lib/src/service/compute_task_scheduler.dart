import 'evalutor.dart';
import '../domain/property.dart';
import '../domain/property_config.dart';
import '../domain/property_descriptor.dart';

/// Worker 执行结果状态
enum WorkerResult {
  idle,        // 没有脏数据，任务结束
  completed,   // 所有任务执行完毕
  retry,       // 需要重新查库建图
}

// 调度, 启动worker, 监听watchHasDirty
abstract class ComputeTaskScheduler {
  void start();

  void stop();
}

// 当ui监听改变时, 应该重新构建优先级队列
abstract class PropertyWatchCounter {
  void subscribe(PropertyKey key);

  void unsubscribe(PropertyKey key);
  Map<PropertyKey, int> get snapshot; // 获取当前快照用于计算
  int get version;
}

// 负责构建图, task优先级队列生成, 跑task
abstract class ComputeTaskWorker {
  Future<WorkerResult> work(PropertyWatchCounter watchState);
}

// 计算值
abstract class ComputeTask {
  Future<void> run();
}

abstract class ComputeTaskFactory {
  ComputeTask create(PropertyKey key);
}

abstract class ComputeContext {
  PropertyDescriptor get descriptor;

  EvalutorContext get evalutorContext;

  Future<T> transcation<T>(Future<T> Function() action);

  Future<PropertyConfig?> getConfig();

  Future<void> markDownstreamDirty();

  Future<void> markAsRefError();

  Future<void> markAsConfigError();

  Future<void> saveProperty(PropertyValue property);

  // 用于配置为空时进行删除
  Future<void> deleteProperty();
}

/// 标记图结构发生变化，需要重新查库的异常
class RebuildGraphException implements Exception {}

/// 具体的结构变化异常
class StructureChangedException extends RebuildGraphException {}

sealed class TaskException implements Exception {}

class NoConfigException extends TaskException {}
