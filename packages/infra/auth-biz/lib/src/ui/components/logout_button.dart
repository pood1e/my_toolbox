import 'package:app_core/di.dart';
import 'package:common_ui/message.dart';
import 'package:flutter/material.dart';

import '../../service/service_provider.dart';

class LogoutButton extends ConsumerWidget {
  final bool iconOnly;

  /// 登出成功后的回调
  final VoidCallback onLogoutSuccess;

  const LogoutButton({
    super.key,
    this.iconOnly = true,
    required this.onLogoutSuccess,
  });

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认登出'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('登出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. 业务逻辑
      final service = await ref.read(authServiceProvider.future);
      await service.logout();
      SnackbarService.showInfo('已退出登录');
      // 2. 成功回调
      // 既然 Dialog 已经关闭，Context 依然有效
      onLogoutSuccess();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (iconOnly) {
      return IconButton(
        icon: const Icon(Icons.logout),
        tooltip: '退出登录',
        onPressed: () => _performLogout(context, ref),
      );
    }
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('退出登录', style: TextStyle(color: Colors.red)),
      onTap: () => _performLogout(context, ref),
    );
  }
}
