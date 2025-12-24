import 'package:core/di.dart';
import 'package:flutter/material.dart';
import 'package:sync_biz/sync_biz.dart';

class SyncSettingsPage extends ConsumerWidget {
  const SyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听异步的设置状态
    final settingsAsync = ref.watch(syncSettingsProvider);

    final syncing = ref.watch(anySyncingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('同步设置')),
      body: settingsAsync.when(
        // A. 加载中
        loading: () => const Center(child: CircularProgressIndicator()),

        // B. 加载失败
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('无法加载设置: $err'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(syncSettingsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),

        // C. 数据就绪
        data: (settings) {
          return ListView(
            children: [
              // 1. 状态卡片
              _buildStatusCard(context, syncing),

              const SizedBox(height: 16),

              // 2. 总开关 (SyncSettings.enable)
              SwitchListTile(
                title: const Text('启用云端同步'),
                subtitle: const Text('在多台设备间保持数据一致'),
                secondary: const Icon(Icons.cloud_sync),
                value: settings.enable,
                onChanged: (val) async {
                  final notifier = ref.read(syncSettingsProvider.notifier);
                  await notifier.save(settings.copyWith(enable: val));

                  // 如果开启，尝试自动触发一次全量同步
                  if (val && context.mounted) {
                    _triggerSync(context, ref);
                  }
                },
              ),

              // 只有开启了总开关，才显示子选项
              if (settings.enable) ...[
                const Divider(),

                // 3. 自动同步
                SwitchListTile(
                  title: const Text('自动同步'),
                  subtitle: const Text('数据发生变更时立即上传'),
                  value: settings.autoSync,
                  onChanged: (val) async {
                    final notifier = ref.read(syncSettingsProvider.notifier);
                    await notifier.save(settings.copyWith(autoSync: val));
                  },
                ),

                // 4. 实时同步 (长连接开关)
                SwitchListTile(
                  title: const Text('实时推送'),
                  subtitle: const Text('即时接收其他设备的变更通知'),
                  value: settings.realtimeSync,
                  onChanged: (val) async {
                    final notifier = ref.read(syncSettingsProvider.notifier);
                    await notifier.save(settings.copyWith(realtimeSync: val));
                  },
                ),

                const SizedBox(height: 32),

                // 5. 手动同步按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.icon(
                    // 如果正在同步，禁用点击
                    onPressed: syncing
                        ? null
                        : () => _triggerSync(context, ref),
                    icon: syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: Text(syncing ? '正在同步...' : '立即同步所有数据'),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text(
                      '提示: 请确保服务器连接正常',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// 封装触发同步的逻辑
  Future<void> _triggerSync(BuildContext context, WidgetRef ref) async {
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

  Widget _buildStatusCard(BuildContext context, bool isSyncing) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: isSyncing
          ? colorScheme.primaryContainer
          : colorScheme.secondaryContainer,
      child: ListTile(
        leading: isSyncing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : Icon(Icons.check_circle, color: colorScheme.primary),
        title: Text(
          isSyncing ? '正在与云端通信...' : '服务连接就绪',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSyncing
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
          ),
        ),
        subtitle: isSyncing ? null : const Text('本地数据已准备好同步'),
      ),
    );
  }
}
