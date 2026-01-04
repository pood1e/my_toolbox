import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import '../../service/service_providers.dart';
import '../../state/launcher_state.dart';

class DesktopScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DesktopScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// --- 常量定义 ---
const double _kSidebarWidth = 72.0; // 侧边栏宽度
const double _kItemHeight = 56.0; // 单个图标高度 (48 + 8 margin)
const double _kHeaderHeight = 80.0; // 顶部 Home 区域高度
const double _kFooterHeight = 80.0; // 底部 Settings 区域高度
const double _kListTopPadding = 8.0; // 【新增】列表顶部的间距常量

class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. 获取路由状态
    final currentPath = GoRouterState.of(context).uri.toString();
    final isDashboard = currentPath == AppRoutes.dashboard; // 假设的路由
    final isSettings = currentPath.startsWith(AppRoutes.settings);
    final isAppsLibrary = currentPath == AppRoutes.launcher;

    // 2. 获取新的数据流 (Stream)
    final uiStateAsync = ref.watch(appEntrancesProvider);

    // 3. 数据扁平化处理
    // Sidebar 策略：优先显示 Recent，空间够再显示 Others
    // 如果正在加载或出错，这里给个空列表，保证 Sidebar 框架不塌陷
    final List<AppDefinition> allApps = uiStateAsync.maybeWhen(
      data: (state) => state,
      orElse: () => [],
    );

    return Container(
      width: _kSidebarWidth,
      decoration: BoxDecoration(color: colorScheme.surface),
      child: Column(
        children: [
          // =================================================
          // 1. Header: 仪表盘
          // =================================================
          SizedBox(
            height: _kHeaderHeight,
            child: Center(
              child: _SidebarItem(
                icon: Icons.dashboard_rounded,
                label: '仪表盘',
                isSelected: isDashboard,
                onTap: () => context.go(AppRoutes.dashboard),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: colorScheme.outlineVariant),
          ),

          // =================================================
          // 2. Body: 动态应用列表 (带溢出计算)
          // =================================================
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 计算逻辑保持不变，这是非常稳健的 UI 适配写法
                final fullHeight = constraints.maxHeight;
                final availableForItems = fullHeight - _kListTopPadding;
                // 向下取整，确保不会显示半个图标
                final int maxCapacity = (availableForItems / _kItemHeight)
                    .floor();

                final int totalAppsCount = allApps.length;

                List<AppDefinition> visibleApps;
                bool showOverflowButton;

                if (maxCapacity <= 0) {
                  // 极端情况：高度极小
                  visibleApps = [];
                  showOverflowButton = true;
                } else if (totalAppsCount <= maxCapacity) {
                  // 空间足够放下所有应用
                  visibleApps = allApps;
                  showOverflowButton = false;
                } else {
                  // 空间不足：留一个位置给 "..." 按钮
                  final cutOffIndex = maxCapacity - 1;
                  visibleApps = allApps.sublist(
                    0,
                    cutOffIndex < 0 ? 0 : cutOffIndex,
                  );
                  showOverflowButton = true;
                }

                return ListView(
                  padding: const EdgeInsets.only(top: _kListTopPadding),
                  // 防止在很少应用时也能滚动
                  physics: const ClampingScrollPhysics(),
                  children: [
                    for (final app in visibleApps)
                      SizedBox(
                        height: _kItemHeight,
                        child: Center(
                          child: _SidebarItem(
                            icon: app.icon,
                            label: app.name,
                            // 如果当前路径匹配该 App 的路由，则高亮
                            isSelected: currentPath.startsWith(app.route),
                            onTap: () async {
                              // 使用 push 还是 go 取决于你的导航策略
                              context.push(app.route);
                              final service = await ref.read(
                                launcherServiceProvider.future,
                              );
                              service.record(app.id);
                            },
                          ),
                        ),
                      ),

                    // 溢出按钮 "..."
                    if (showOverflowButton)
                      SizedBox(
                        height: _kItemHeight,
                        child: Center(
                          child: _SidebarItem(
                            icon: Icons.grid_view_rounded,
                            label: '更多',
                            isSelected: isAppsLibrary,
                            onTap: () => context.go(AppRoutes.launcher),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: colorScheme.outlineVariant),
          ),

          // =================================================
          // 3. Footer: 设置
          // =================================================
          SizedBox(
            height: _kFooterHeight,
            child: Center(
              child: _SidebarItem(
                icon: Icons.settings_outlined,
                label: '设置',
                isSelected: isSettings,
                onTap: () => context.go(AppRoutes.settings),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 私有子组件：侧边栏图标按钮
// -------------------------------------------------------------
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 选中状态颜色逻辑
    final fgColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    final bgColor = isSelected
        ? colorScheme.primaryContainer
        : Colors.transparent;

    return Tooltip(
      message: label, // 鼠标悬停显示文字
      waitDuration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4), // 内部上下间距
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          // 鼠标悬停时的背景色
          hoverColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: fgColor, size: 24),
          ),
        ),
      ),
    );
  }
}
