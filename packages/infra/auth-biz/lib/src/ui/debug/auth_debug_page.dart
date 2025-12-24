import 'package:app_core/di.dart';
import 'package:common_ui/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../service/service_provider.dart';
import '../../state/auth_state_notifier.dart';

class DebugPage extends ConsumerStatefulWidget {
  final VoidCallback onGoLogin;
  final VoidCallback onGoRegister;

  const DebugPage({
    super.key,
    required this.onGoLogin,
    required this.onGoRegister,
  });

  @override
  ConsumerState<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends ConsumerState<DebugPage> {
  @override
  void initState() {
    super.initState();
    // 核心逻辑：页面加载后自动执行检查
    // 使用 addPostFrameCallback 确保在构建完成后执行，避免构建期间修改 Provider 的冲突
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = await ref.read(tokenServiceProvider.future);
      service.checkTokenValidation();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 监听状态
    final user = ref.watch(userIdProvider).value;
    final role = ref.watch(roleProvider).value;
    final token = ref.watch(accessTokenProvider).value;
    final server = ref.watch(remoteServerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Auth Debugger')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('User Info'),
            subtitle: Text('ID: ${user ?? "N/A"}\nRole: ${role ?? "N/A"}'),
            leading: const Icon(Icons.person),
          ),
          ListTile(
            title: const Text('Server Config'),
            subtitle: Text(
              server == null
                  ? 'Not Configured'
                  : '${server.tls ? "HTTPS" : "HTTP"}://${server.host}:${server.port}',
            ),
            leading: const Icon(Icons.dns),
          ),
          ListTile(
            title: const Text('Access Token'),
            subtitle: Text(
              token == null ? 'None' : '${token.substring(0, 10)}...',
            ),
            leading: const Icon(Icons.key),
            onTap: token == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: token));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Copied!')));
                  },
          ),

          const Divider(),

          // 2. 动作区
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // 允许手动再次检查
                FilledButton.tonal(
                  onPressed: () async {
                    final service = await ref.read(tokenServiceProvider.future);
                    SnackbarService.showInfo('正在检查 Token...');
                    try {
                      await service.checkTokenValidation();
                      SnackbarService.showSuccess('Token有效');
                    } catch (e) {
                      SnackbarService.showError('检查失败: $e');
                    }
                  },
                  child: const Text('Check Auth (Retry)'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    final service = await ref.read(tokenServiceProvider.future);
                    try {
                      await service.refresh();
                      SnackbarService.showSuccess('Token 刷新成功');
                    } catch (e) {
                      SnackbarService.showError('刷新失败: $e');
                    }
                  },
                  child: const Text('Force Refresh'),
                ),

                // 导航动作
                FilledButton(
                  onPressed: widget.onGoLogin,
                  child: const Text('Go Login'),
                ),
                FilledButton(
                  onPressed: widget.onGoRegister,
                  child: const Text('Go Register'),
                ),

                // 登出动作
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final service = await ref.read(authServiceProvider.future);
                    await service.logout();
                    SnackbarService.showInfo('已退出登录');
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
