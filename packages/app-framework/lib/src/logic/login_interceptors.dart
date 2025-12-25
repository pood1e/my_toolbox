import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';
import 'package:app_core/route.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:data_biz/data_biz.dart';
import 'package:flutter/material.dart';

part 'login_interceptors.g.dart';

@Riverpod(keepAlive: true)
BeforeLogin closeUserScopeBeforeLogin(Ref ref) {
  return (userId) async {
    await ref.read(closeUserActionProvider)();
    return true;
  };
}

@Riverpod(keepAlive: true)
BeforeLogout closeUserScopeBeforeLogout(Ref ref) {
  return (userId) async {
    await ref.read(closeUserActionProvider)();
  };
}

@Riverpod(keepAlive: true)
BeforeLogin migrateBeforeLogin(Ref ref) {
  return (userId) async {
    // ==========================================================
    // 步骤 1: 【关键】在做任何 await 之前，先捕获所有需要的 Action
    // ==========================================================

    // 1. 获取检查 Action
    final checkAnyNeedMigrateAction = ref.read(checkAnyNeedMigrateProvider);

    // 2. 提前获取清除 Action (即使后面可能用不到，也要先拿在手里)
    final clearGuestAction = ref.read(clearGuestActionProvider);

    // 3. 提前获取合并 Action (userId 此时已经是已知的，可以直接传入)
    final migrateAction = ref.read(migrateFromGuestActionProvider(userId));

    // ==========================================================
    // 步骤 2: 开始异步逻辑 (此时不再使用 ref)
    // ==========================================================

    // 第一个 await：如果有问题，此时 ref 可能就会失效，但我们上面已经拿到了 action
    final hasGuestData = await checkAnyNeedMigrateAction();

    if (!hasGuestData) return true;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return true;

    // 第二个 await：用户看弹窗思考的时间可能很长
    final decision = await showDialog<_MigrationDecision>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        // ... (UI代码保持不变) ...
        title: const Text('数据迁移'),
        content: const Text('检测到您有游客数据，是否需要合并到新账号？'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _MigrationDecision.cancel),
            child: const Text('取消登录'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _MigrationDecision.discard),
            child: const Text('清除游客数据'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _MigrationDecision.merge),
            child: const Text('合并数据'),
          ),
        ],
      ),
    );

    switch (decision) {
      case _MigrationDecision.cancel:
      case null:
        return false;

      case _MigrationDecision.discard:
        // ✅ 修复：直接使用上面保存好的 clearGuestAction，而不是 ref.read
        await clearGuestAction();
        return true;

      case _MigrationDecision.merge:
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        try {
          // ✅ 修复：直接使用上面保存好的 migrateAction
          await migrateAction();
        } catch (e) {
          // logger.e('Migration failed: $e');
          // 确保 logger 也是全局的或者提前获取的
          logger.e('Migration failed: $e');
        } finally {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
        return true;
    }
  };
}

enum _MigrationDecision { cancel, discard, merge }
