import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../components/pomodoro_operation_area.dart';
import '../components/pomodoro_process_indicator.dart';
import '../components/pomodoro_session_panel.dart';
import '../pomodoro_state.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPomodoro = ref.watch(activePomodoroProvider);
    final sheetController = ref.watch(pomodoroSheetControllerProvider);

    return asyncPomodoro.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (pomodoro) {
        if (pomodoro == null) return const SizedBox.shrink();
        return DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: 0.0,
          minChildSize: 0.0,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0, 1.0],

          builder: (context, scrollController) {
            return _SheetBackground(
              // 关键：点击露出的把手区域也能展开
              onTapHandleArea: () {
                if (sheetController.isAttached && sheetController.size < 0.5) {
                  sheetController.animateTo(
                    1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                  );
                }
              },
              child: _FullContent(
                pomodoro: pomodoro,
                scrollController: scrollController,
                sheetController: sheetController,
              ),
            );
          },
        );
      },
    );
  }
}

// =========================================================
// 组件 1: 背景容器
// =========================================================
class _SheetBackground extends StatelessWidget {
  final Widget child;
  final VoidCallback onTapHandleArea;

  const _SheetBackground({required this.child, required this.onTapHandleArea});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        // 处理点击事件：当用户点击露出的那一小条时，触发展开
        // 因为内容区可能还没铺满，GestureDetector 放在这里兜底
        onTap: onTapHandleArea,
        child: child,
      ),
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
    return CustomScrollView(
      controller: scrollController, // 绑定后，拖拽灰色条或空白处均可上拉
      slivers: [
        // 1. 顶部把手区域 (收起时唯一可见的部分)
        SliverToBoxAdapter(
          child: _HeaderHandle(
            onCollapse: () => sheetController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ),

        // 2. 主内容区域
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              spacing: 16,
              children: [
                Center(
                  child: PomodoroProcessIndicator(
                    pomodoro: pomodoro,
                    size: 200,
                  ),
                ),
                PomodoroSessionPanel(session: pomodoro.session),
                PomodoroOperationArea(pomodoro: pomodoro),
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
    // 增加顶部 Padding 确保把手位置适中
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      // 这里的颜色设置为透明，确保点击事件能穿透给 ScrollView 或背景的 GestureDetector
      color: Colors.transparent,
      child: Column(
        children: [
          // 灰色拖拽条 (Visual Handle)
          // 这是收起状态下用户主要看到的东西
          Center(
            child: Container(
              width: 48, // 稍微加宽一点，更易识别
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400, // 稍微加深一点颜色
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // 收起按钮 (展开时才需要点击，收起时它是被隐藏在屏幕下方的)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              tooltip: "收起",
              onPressed: onCollapse,
            ),
          ),
        ],
      ),
    );
  }
}
