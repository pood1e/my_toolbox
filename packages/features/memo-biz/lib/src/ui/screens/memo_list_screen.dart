import 'package:app_core/di.dart';
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
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MemoEditorScreen()));
          },
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
    // 根据状态选择不同的 Provider
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
                  size: 64,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 16),
                Text(
                  'No memos found',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: memos.length,
          padding: const EdgeInsets.only(bottom: 80), // 避让 FAB
          itemBuilder: (context, index) {
            final memo = memos[index];
            return MemoTile(
              memo: memo,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MemoEditorScreen(memo: memo),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
