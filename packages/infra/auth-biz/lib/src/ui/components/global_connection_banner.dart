import '../../../auth_biz.dart';
import 'package:common_ui/message.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import 'connection_ui_model.dart';

class GlobalConnectionBanner extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalConnectionBanner({super.key, required this.child});

  @override
  ConsumerState<GlobalConnectionBanner> createState() =>
      _GlobalConnectionBannerState();
}

class _GlobalConnectionBannerState
    extends ConsumerState<GlobalConnectionBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(connectionAvailabiltyProvider);

    // 状态流监听：状态改变时重置关闭标记
    // 逻辑流：Offline(显示) -> 点击重试 -> Verifying(隐藏, _isDismissed重置) -> Offline(再次显示)
    ref.listen(connectionAvailabiltyProvider, (prev, next) {
      if (prev != next) {
        // 只要状态变了，就重置 dismissed。
        // 这样如果 verifying 失败变回 offline，Banner 会重新弹出来。
        if (_isDismissed) setState(() => _isDismissed = false);
      }
    });

    final bool isVisible = status.shouldShowBanner && !_isDismissed;

    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: isVisible
                  ? Material(
                      type: MaterialType.transparency,
                      child: _buildFloatingBanner(context, status),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBanner(
    BuildContext context,
    ConnectionAvailability status,
  ) {
    return Container(
      key: ValueKey(status),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: status.accentColor.withValues(alpha: .1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          status.icon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.message,
              style: TextStyle(
                color: status.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          _buildActions(context, status),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ConnectionAvailability status) {
    // 因为 verifying 不显示了，这里肯定是有按钮的
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == ConnectionAvailability.offline)
          _SmallActionButton(
            label: '重试',
            color: status.accentColor,
            onTap: () async {
              final service = await ref.read(tokenServiceProvider.future);
              SnackbarService.showInfo('正在检查 Token...');
              try {
                await service.checkTokenValidation();
                SnackbarService.showSuccess('Token有效');
              } catch (e) {
                SnackbarService.showError('检查失败: $e');
              }
            },
          ),

        if (status == ConnectionAvailability.expired)
          _SmallActionButton(
            label: '去登陆',
            color: status.accentColor,
            onTap: () {
              context.go('/login');
              setState(() => _isDismissed = true);
            },
          ),

        const SizedBox(width: 8),

        // 关闭按钮 (Offline 和 Expired 都是可关闭的)
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => setState(() => _isDismissed = true),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.close,
                size: 18,
                color: status.accentColor.withValues(alpha: .6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 修复点 3: _SmallActionButton 内部已经使用了 Material，所以这里是安全的
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
