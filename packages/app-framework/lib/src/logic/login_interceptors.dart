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
    final checkAnyNeedMigrateAction = ref.read(checkAnyNeedMigrateProvider);
    final clearGuestAction = ref.read(clearGuestActionProvider);
    final migrateAction = ref.read(migrateFromGuestActionProvider(userId));

    final hasGuestData = await checkAnyNeedMigrateAction();
    if (!hasGuestData) return true;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return true;

    final decision = await showDialog<_MigrationDecision>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('数据迁移'),
        content: const Text('检测到您有游客数据，是否需要合并到账号？'),
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
          await migrateAction();
        } catch (e) {
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
