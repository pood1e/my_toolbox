import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:flutter/material.dart';
import 'package:framework_api/framework_api.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsync = ref.watch(currentUserIdentityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: userIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (userId) {
          final isLoggedIn = userId != null;

          return ListView(
            children: [
              // ==============================
              // 1. 账户区域
              // ==============================
              _SectionHeader(title: '账户'),
              if (isLoggedIn)
                _buildUserProfile(context, ref, userId)
              else
                _buildGuestTile(context),

              // ==============================
              // 2. 同步区域 (仅登录显示)
              // ==============================
              if (isLoggedIn) ...[
                const Divider(),
                _SectionHeader(title: '数据同步'),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('同步设置'),
                  subtitle: const Text('管理自动同步、立即同步'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '${AppRoutes.settings}/${AppRoutes.syncSettingsPart}',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // --- 组件构建 ---

  Widget _buildUserProfile(
    BuildContext context,
    WidgetRef ref,
    UserIdentity user,
  ) {
    return ListTile(
      leading: CircleAvatar(child: Text(user.userId[0].toUpperCase())),
      title: Text(
        user.userId,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(user.server.host),
      // 可以加个编辑资料入口
      trailing: LogoutButton(onLogoutSuccess: () {}),
    );
  }

  Widget _buildGuestTile(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: const Text('未登录'),
      subtitle: const Text('登录以在多设备间同步数据'),
      trailing: FilledButton.tonal(
        onPressed: () {
          context.push('/login');
        },
        child: const Text('登录 / 注册'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
