// File: compute_service.dart

import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../value/value_service.dart';
import 'impl/compute_node.dart';
import 'impl/compute_service_impl.dart';
import 'source/ref_source.dart';

part 'compute_service.freezed.dart';
part 'compute_service.g.dart';

/// 计算过程中的特定异常类型
enum ComputeError {
  valueInvalid,
  configInvalid,
  referenceInvalid,
  cycleDependencies,
}

/// 计算异常类
class ComputeException implements Exception {
  final ComputeError error;
  final String? message;

  ComputeException({required this.error, this.message});

  @override
  String toString() {
    if (message != null) {
      return 'ComputeException: ${error.name} - $message';
    }
    return 'ComputeException: ${error.name}';
  }
}

/// 计算图的边元数据定义 (描述节点之间的连接拓扑关系)
@freezed
abstract class ComputeMeta with _$ComputeMeta {
  const factory ComputeMeta({
    required ComputeNode compute, // 当前节点
    ComputeNode? next, // 下游节点 (如果为 null 且没有其他节点依赖它，则被视为终点 Sink Node)
  }) = _ComputeMeta;
}

/// 业务属性配置可混入的协议，要求提供基于配置生成计算图的能力
mixin PropertyComputeMeta<C> on PropertyValueMeta {
  /// 传入总配置，构建并返回计算图的边定义，引擎会自动推导执行链路
  List<ComputeMeta> buildComputeGraph(C cfg);
}

/// 计算服务对外暴露的底层接口
abstract class ComputeService {
  /// 传入拓扑描述列表，内部执行解析并返回图的最终计算结果
  Future<dynamic> compute(List<ComputeMeta> metas);
}

/// 全局计算服务的 Riverpod Provider
/// 在这里注册你所有的可复用 (Reuse) 计算逻辑单元
@riverpod
Future<ComputeService> computeService(Ref ref) async {
  final valueService = await ref.watch(valueServiceProvider.future);

  return ComputeServiceImpl(
    sources: [RefSource(valueService: valueService)],
    processors: [
      // 示例:
      // Processor(
      //   computeId: 'format_user_data',
      //   process: (source, config) async => format(source, config),
      // ),
    ],
    aggregators: [
      // 示例:
      // Aggregator(
      //   computeId: 'merge_user_and_permissions',
      //   aggregate: (sMap, config) async => merge(sMap, config),
      // ),
    ],
  );
}
