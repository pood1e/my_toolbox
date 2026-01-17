import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../../providers.dart';
import '../components/pomodoro_operation_area.dart';
import '../components/pomodoro_process_indicator.dart';
import '../components/pomodoro_session_panel.dart';
import '../state/logical_state.dart';
import '../state/trigger_state.dart';
import '../state/ui_state.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听状态 (Idle / Running / Pending)
    final phase = ref.watch(currentPomodoroPhaseProvider);
    // 2. 监听数据
    final pomodoro = ref.watch(latestPomodoroProvider).value;
    // 3. 获取控制器
    final sheetController = ref.watch(pomodoroSheetControllerProvider);

    ref.listen<PomodoroPhase>(currentPomodoroPhaseProvider, (
      previous,
      next,
    ) async {
      // 触发条件 1: 状态从 Running 变为 Pending (意味着倒计时刚归零)
      if (previous == PomodoroPhase.running && next == PomodoroPhase.pending) {
        // 获取当前的任务快照 (此时 pomodoro 可能还没更新，所以我们要用 read 获取最新的)
        // 或者直接使用外层的 pomodoro 变量(它是最新的 watch 结果)
        final currentPomodoro = ref.read(latestPomodoroProvider).value;

        if (currentPomodoro != null) {
          // 触发条件 2: 当前类型是 Focus (专注)
          if (currentPomodoro.type == PomodoroType.focus) {
            logger.i('⚡️ 检测到专注结束，UI 触发自动流转...');

            final service = await ref.read(pomodoroServiceProvider.future);
            // 执行自动跳转 (Focus -> Break)
            await service.nextPhase(currentPomodoro.id);
          }
          // 如果是 Break，什么都不做，停留在 Pending 状态等待用户
        }
      }
    });

    // 核心逻辑：只有在非 Idle 且有数据时才挂载 Sheet
    if (phase == PomodoroPhase.idle || pomodoro == null) {
      return const SizedBox.shrink();
    }

    // 4. 配置 Sheet
    return DraggableScrollableSheet(
      controller: sheetController,
      // 默认完全隐藏 (0.0)
      initialChildSize: 0.0,
      minChildSize: 0.0,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.0, 1.0],

      // 只有两个状态：隐藏 或 全屏
      builder: (context, scrollController) {
        return _SheetBackground(
          child: _FullContent(
            pomodoro: pomodoro,
            scrollController: scrollController,
            sheetController: sheetController,
          ),
        );
      },
    );
  }
}

// =========================================================
// 组件 1: 背景容器 (提供 Material 上下文和样式)
// =========================================================
class _SheetBackground extends StatelessWidget {
  final Widget child;

  const _SheetBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      color: Theme.of(context).colorScheme.surface,
      // 只有顶部圆角，模拟抽屉效果
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// =========================================================
// 组件 2: 全屏内容布局
// =========================================================
class _FullContent extends StatelessWidget {
  final Pomodoro pomodoro;
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;

  const _FullContent({
    required this.pomodoro,
    required this.scrollController,
    required this.sheetController,
  });

  @override
  Widget build(BuildContext context) {
    // 使用 CustomScrollView 配合 DraggableScrollableSheet
    return CustomScrollView(
      controller: scrollController, // 必须绑定，否则无法拖拽
      slivers: [
        // 1. 顶部把手区域
        SliverToBoxAdapter(
          child: _HeaderHandle(
            onCollapse: () {
              // 点击收起：高度变为 0.0
              sheetController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),

        // 2. 主内容区域 (自适应填满剩余空间)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 顶部留一点空间
                const SizedBox(height: 10),

                // 会话信息面板 (名称 + 备注 + 完成按钮)
                PomodoroSessionPanel(session: pomodoro.session),

                // 状态环 (倒计时 + 进度)
                Center(
                  child: PomodoroProcessIndicator(
                    pomodoro: pomodoro,
                    size: 280,
                  ),
                ),

                // 操作区 (Running/Pending 按钮组)
                PomodoroOperationArea(pomodoro: pomodoro),

                // 底部留白，视觉平衡
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================
// 组件 3: 顶部把手与收起按钮
// =========================================================
class _HeaderHandle extends StatelessWidget {
  final VoidCallback onCollapse;

  const _HeaderHandle({required this.onCollapse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          // 灰色小横条 (视觉提示：此处可拖拽)
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // 收起按钮
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              tooltip: '收起',
              onPressed: onCollapse,
            ),
          ),
        ],
      ),
    );
  }
}
