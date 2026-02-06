import 'package:app_core/core.dart';
import 'package:flutter/material.dart';

class SnackbarService {
  SnackbarService._();

  /// 显示成功消息 (绿色)
  static void showSuccess(String message) {
    _show(
      message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle_outline,
    );
  }

  /// 显示错误消息 (红色)
  static void showError(String message) {
    _show(
      message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
    );
  }

  /// 显示普通/警告消息 (蓝色/深色)
  static void showInfo(String message) {
    _show(
      message,
      backgroundColor: Colors.blueGrey.shade700,
      icon: Icons.info_outline,
    );
  }

  /// 内部通用实现
  static void _show(
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    // 核心逻辑：通过 key 获取 state
    final state = rootScaffoldMessengerKey.currentState;
    if (state == null) return;

    // 清除当前正在显示的 Snackbar (防止堆积)
    state.removeCurrentSnackBar();

    state.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // 悬浮样式，更好看
        backgroundColor: backgroundColor,
        elevation: 6.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        // 四周留白
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // 支持滑动关闭
        dismissDirection: DismissDirection.horizontal,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
