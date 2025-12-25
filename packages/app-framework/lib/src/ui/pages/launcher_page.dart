import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import '../../service/service_providers.dart';
import '../../state/launcher_state.dart';

class LauncherPage extends ConsumerStatefulWidget {
  const LauncherPage({super.key});

  @override
  ConsumerState<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends ConsumerState<LauncherPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 获取合并后的实时数据流
    final stateAsync = ref.watch(appEntrancesProvider);

    return Scaffold(
      body: SafeArea(
        child: stateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('加载失败: $err')),
          data: (uiState) {
            // 2. 处理搜索逻辑 (本地过滤)
            if (_searchQuery.isNotEmpty) {
              return _buildSearchResults(context, uiState);
            }
            // 3. 正常分组显示
            return _buildGroupedView(context, uiState);
          },
        ),
      ),
    );
  }

  // --- 视图 1: 正常分组视图 ---
  Widget _buildGroupedView(BuildContext context, List<AppDefinition> apps) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSearchBar()),

        _buildGrid(apps),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  // --- 视图 2: 搜索结果视图 ---
  Widget _buildSearchResults(
    BuildContext context,
    List<AppDefinition> allApps,
  ) {
    final results = allApps.where((app) {
      // 支持拼音搜索可在这里扩展
      return app.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSearchBar()),

        if (results.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('未找到相关应用', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          _buildGrid(results),
      ],
    );
  }

  // --- 组件: 搜索框 ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SearchBar(
        controller: _searchCtrl,
        leading: const Icon(Icons.search),
        hintText: '搜索功能...',
        elevation: WidgetStateProperty.all(0),
        // 使用 Surface Container 颜色，适配 Material 3
        backgroundColor: WidgetStateProperty.all(
          Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        trailing: _searchQuery.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                    // 收起键盘
                    FocusScope.of(context).unfocus();
                  },
                ),
              ]
            : null,
      ),
    );
  }

  // --- 组件: 应用网格 ---
  Widget _buildGrid(List<AppDefinition> apps) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 100,
          mainAxisSpacing: 24, // 稍微加大间距
          crossAxisSpacing: 16,
          childAspectRatio: 0.8, // 调整比例适配文字
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final app = apps[index];
          return _LibraryAppIcon(
            app: app,
            onTap: () async {
              context.go(app.route);
              final service = await ref.read(launcherServiceProvider.future);
              service.record(app.id);
            },
          );
        }, childCount: apps.length),
      ),
    );
  }
}

// --- 组件: 单个应用图标 (保持不变，微调样式) ---
class _LibraryAppIcon extends StatelessWidget {
  final AppDefinition app;
  final VoidCallback onTap;

  const _LibraryAppIcon({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Material(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Icon(
                app.icon,
                size: 28,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          app.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
