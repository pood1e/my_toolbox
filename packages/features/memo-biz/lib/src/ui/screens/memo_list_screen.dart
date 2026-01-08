import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../components/memo_tile.dart';
import '../ui_state.dart';
import 'memo_editor_screen.dart';

class MemoListScreen extends StatelessWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Archived'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MemoListView(isArchived: false),
            _MemoListView(isArchived: true),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const MemoEditorScreen())),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _MemoListView extends ConsumerWidget {
  final bool isArchived;

  const _MemoListView({required this.isArchived});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(
      isArchived ? archivedMemosProvider : activeMemosProvider,
    );

    return memosAsync.when(
      data: (memos) {
        if (memos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isArchived ? Icons.archive_outlined : Icons.note_alt_outlined,
                  size: AppSizes.illustration, // 64.0
                  color: context.colorScheme.surfaceContainerHighest,
                ),
                Gaps.v16,
                Text(
                  'No memos found',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: memos.length,
          // 底部留出安全距离，防止 FAB 遮挡最后一条
          padding: const EdgeInsets.only(bottom: AppSpacings.fabSafe),
          itemBuilder: (context, index) {
            final memo = memos[index];
            return MemoTile(
              memo: memo,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MemoEditorScreen(memo: memo)),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
