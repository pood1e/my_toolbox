import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';
import 'package:flutter/material.dart';

extension AsyncValueUI<T> on AsyncValue<T> {
  /// 通用封装的 when
  Widget whenUI({
    required Widget Function(T data) data,
    Widget Function(Object error, StackTrace stackTrace)? error,
    Widget Function()? loading,
    bool skipLoadingOnReload = false, // 刷新时是否跳过 loading（保留旧数据）
    bool skipLoadingOnRefresh = true, // 下拉刷新时是否不显示 loading
    bool skipError = false,
  }) => when(
    skipLoadingOnReload: skipLoadingOnReload,
    skipLoadingOnRefresh: skipLoadingOnRefresh,
    skipError: skipError,
    data: data,
    // 1. 优先使用传入的 error 处理
    // 2. 否则使用全局默认错误页
    error:
        error ??
        (e, s) {
          logger.e('error : ${e.toString()}', error: e, stackTrace: s);
          return DefaultErrorWidget(error: e);
        },
    // 1. 优先使用传入的 loading 处理
    // 2. 否则使用全局默认 Loading
    loading: loading ?? () => const DefaultLoadingWidget(),
  );
}

// --- 下面是全局统一的组件，你可以改成你自己的样式 ---

class DefaultLoadingWidget extends StatelessWidget {
  const DefaultLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      const CircularProgressIndicator.adaptive();
}

class DefaultErrorWidget extends StatelessWidget {
  final Object error;

  const DefaultErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 8),
        Text('发生错误: $error'),
      ],
    ),
  );
}
