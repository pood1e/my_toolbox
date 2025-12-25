import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../domain/sync_settings.dart';
import '../../service/service_providers.dart';
import '../../state/sync_settings_state.dart';

class SyncSettingsPage extends ConsumerWidget {
  const SyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听设置配置
    final settingsAsync = ref.watch(syncSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('同步设置')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorView(error: err, ref: ref),
        data: (settings) => _SettingsContent(settings: settings),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final WidgetRef ref;

  const _ErrorView({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('无法加载设置: $error'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.refresh(syncSettingsProvider),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  final SyncSettings settings;

  const _SettingsContent({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        // 1. 总开关
        _GlobalSyncSwitch(
          value: settings.enable,
          onChanged: (val) async {
            final notifier = ref.read(syncSettingsProvider.notifier);
            await notifier.save(settings.copyWith(enable: val));

            if (val && context.mounted) {
              _ManualSyncSection.triggerSync(context, ref);
            }
          },
        ),

        const Divider(height: 1),

        // 2. 只有开启才显示后续
        if (settings.enable) ...[
          const SizedBox(height: 16),
          // 状态卡片 (已修改支持异步)
          const _SyncStatusCard(),
          const SizedBox(height: 16),
          // 高级选项
          _AdvancedOptionsSection(settings: settings),
          const SizedBox(height: 32),
          // 手动同步按钮 (已修改支持异步)
          const _ManualSyncSection(),
          const SizedBox(height: 50),
        ],
      ],
    );
  }
}

class _GlobalSyncSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GlobalSyncSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: const Text(
        '启用云端同步',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('在多台设备间保持数据一致'),
      secondary: Icon(
        Icons.cloud_sync,
        color: value ? Theme.of(context).primaryColor : Colors.grey,
        size: 28,
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// 修改点 1: 处理异步状态的卡片
class _SyncStatusCard extends ConsumerWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听异步状态
    final syncingAsync = ref.watch(anySyncingProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // 根据 AsyncValue 构建不同的 UI 内容
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: syncingAsync.when(
        // A. 正在检查同步状态 (Loading)
        loading: () => Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          child: const ListTile(
            leading: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('正在检查同步状态...'),
          ),
        ),

        // B. 检查状态出错
        error: (err, _) => Card(
          elevation: 0,
          color: colorScheme.errorContainer,
          child: ListTile(
            leading: Icon(Icons.error, color: colorScheme.error),
            title: Text('无法获取同步状态: $err'),
          ),
        ),

        // C. 获取到状态 (Bool)
        data: (isSyncing) {
          final color = isSyncing
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest;

          final onColor = isSyncing
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant;

          return Card(
            elevation: 0,
            color: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: isSyncing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: onColor,
                      ),
                    )
                  : Icon(Icons.check_circle, color: colorScheme.primary),
              title: Text(
                isSyncing ? '正在与云端通信...' : '服务连接就绪',
                style: TextStyle(fontWeight: FontWeight.bold, color: onColor),
              ),
              subtitle: isSyncing ? null : const Text('本地数据已准备好同步'),
            ),
          );
        },
      ),
    );
  }
}

class _AdvancedOptionsSection extends ConsumerWidget {
  final SyncSettings settings;

  const _AdvancedOptionsSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            '高级选项',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('自动同步'),
          subtitle: const Text('数据发生变更时立即上传'),
          value: settings.autoSync,
          onChanged: (val) {
            ref
                .read(syncSettingsProvider.notifier)
                .save(settings.copyWith(autoSync: val));
          },
        ),
        SwitchListTile(
          title: const Text('实时推送'),
          subtitle: const Text('即时接收其他设备的变更通知'),
          value: settings.realtimeSync,
          onChanged: (val) {
            ref
                .read(syncSettingsProvider.notifier)
                .save(settings.copyWith(realtimeSync: val));
          },
        ),
      ],
    );
  }
}

/// 修改点 2: 处理异步状态的按钮
class _ManualSyncSection extends ConsumerWidget {
  const _ManualSyncSection();

  static Future<void> triggerSync(BuildContext context, WidgetRef ref) async {
    try {
      final syncAllService = await ref.read(syncAllServiceProvider.future);
      await syncAllService.syncAll();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('同步请求已发送')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听异步值
    final syncingAsync = ref.watch(anySyncingProvider);

    // 提取状态：如果是 loading 或 值为 true，都视为“忙碌/不可点击”
    final isBusy = syncingAsync.isLoading || (syncingAsync.value ?? false);
    final hasError = syncingAsync.hasError;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              // 如果出错，允许点击重试；如果忙碌，禁用
              onPressed: (isBusy && !hasError)
                  ? null
                  : () => triggerSync(context, ref),

              icon: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync),

              label: Text(
                hasError ? '状态未知，点击重试同步' : (isBusy ? '正在同步...' : '立即同步所有数据'),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            '提示: 请确保服务器连接正常',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
