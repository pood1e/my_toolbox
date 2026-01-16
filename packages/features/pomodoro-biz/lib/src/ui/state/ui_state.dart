import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../../providers.dart';
import 'logical_state.dart';

part 'ui_state.g.dart';

@riverpod
Stream<List<Pomodoro>> _rawHistory(Ref ref) async* {
  final service = await ref.watch(pomodoroServiceProvider.future);
  yield* service.watchAll();
}

@riverpod
List<Pomodoro> pomodoroHistory(Ref ref) {
  // 1. 监听原始数据 (数据库变动时自动更新)
  // 当从 Waiting -> Running 时，数据库会写入新记录，_rawHistory 更新，
  // 本 Provider 会自动重算，因此不需要额外的 Trigger。
  final rawList = ref.watch(_rawHistoryProvider).value ?? [];

  // 2. [核心优化] 精准监听状态流转
  // 我们不 watch phase，而是 listen。
  ref.listen<PomodoroPhase>(currentPomodoroPhaseProvider, (previous, next) {
    // 逻辑：只有当状态从 "Running" 变为 "非Running" (Pending/Idle) 时，
    // 意味着倒计时刚刚归零，我们需要刷新列表以把刚才那个任务显示出来。
    if (previous == PomodoroPhase.running && next != PomodoroPhase.running) {
      // 强制让自己失效，重新执行 build，从而获取最新的 DateTime.now()
      ref.invalidateSelf();
    }
  });

  // 3. 执行过滤
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  return rawList.where((p) {
    return p.endAt <= nowMs;
  }).toList();
}

// 全局唯一的 Sheet 控制器，用于在 FAB 点击时控制面板展开/收起
@riverpod
Raw<DraggableScrollableController> pomodoroSheetController(Ref ref) {
  return DraggableScrollableController();
}
