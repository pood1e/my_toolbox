import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../components/document_card.dart';
import '../state/ui_state.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 Inbox 数据流
    final asyncDocs = ref.watch(inboxDocumentsProvider);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,

      // 使用 CustomScrollView 是为了让 AppBar 能随列表滚动 (Sliver 效果)
      // 如果你想要完全固定的 AppBar，也可以用 Scaffold.appBar + ListView
      body: CustomScrollView(
        slivers: [
          // 1. AppBar
          SliverAppBar(
            title: const Text('收件箱'),
            centerTitle: false,
            floating: true,
            // 向下滑动时立即出现
            snap: true,
            pinned: true,
            // 即使向上滚动，也会保留一个最小高度的 AppBar
            backgroundColor: context.colorScheme.surface,
            surfaceTintColor: context.colorScheme.surfaceTint,
          ),

          // 2. Document List
          asyncDocs.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('加载失败: $err'))),
            data: (docs) {
              if (docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('没有笔记，去记一笔吧')),
                );
              }

              return SliverPadding(
                // 给列表加一点底部内边距，防止被 FAB 遮挡
                padding: const EdgeInsets.only(bottom: AppSpacings.fabSafe),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final doc = docs[index];
                    return DocumentCard(
                      document: doc!,
                      onTap: () => context.push('/note/document/${doc.id}'),
                    );
                  }, childCount: docs.length),
                ),
              );
            },
          ),
        ],
      ),

      // 3. FAB (添加按钮)
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/note/document/new'),
        child: const Icon(Icons.edit),
      ),
    );
  }
}
