import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServerConfigPanel extends StatefulWidget {
  final TextEditingController hostController;
  final TextEditingController portController;
  final ValueNotifier<bool> tlsNotifier;

  const ServerConfigPanel({
    super.key,
    required this.hostController,
    required this.portController,
    required this.tlsNotifier,
  });

  @override
  State<ServerConfigPanel> createState() => _ServerConfigPanelState();
}

class _ServerConfigPanelState extends State<ServerConfigPanel> {
  @override
  void initState() {
    super.initState();
    // 监听输入变化以实时更新收起状态下的摘要信息
    widget.hostController.addListener(_refreshUi);
    widget.portController.addListener(_refreshUi);
    widget.tlsNotifier.addListener(_refreshUi);
  }

  @override
  void dispose() {
    widget.hostController.removeListener(_refreshUi);
    widget.portController.removeListener(_refreshUi);
    widget.tlsNotifier.removeListener(_refreshUi);
    super.dispose();
  }

  void _refreshUi() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacings.xl),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacings.l),
        shape: const Border(),
        // 去除 ExpansionTile 自带的边框
        leading: Icon(
          Icons.settings_ethernet,
          color: theme.colorScheme.primary,
        ),
        title: const Text(
          '服务器设置',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _buildHeaderSummary(theme),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacings.l,
          0,
          AppSpacings.l,
          AppSpacings.l,
        ),
        children: [
          const Divider(height: 1),
          Gaps.v16,
          _buildHostInput(),
          Gaps.v12,
          _buildPortAndTlsRow(theme),
        ],
      ),
    );
  }

  /// 构建收起时的摘要信息
  Widget _buildHeaderSummary(ThemeData theme) {
    final host = widget.hostController.text.isEmpty
        ? 'unset'
        : widget.hostController.text;
    final port = widget.portController.text.isEmpty
        ? '?'
        : widget.portController.text;
    final isTls = widget.tlsNotifier.value;

    return Text(
      '$host:$port  •  ${isTls ? "HTTPS" : "HTTP"}',
      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建 Host 输入框
  Widget _buildHostInput() {
    return TextFormField(
      controller: widget.hostController,
      decoration: AppInputStyles.outline(
        label: '主机地址 (Host / IP)',
        prefixIcon: Icons.dns_outlined,
      ),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next, // 优化：按回车跳到下一个输入框
    );
  }

  /// 构建 Port 和 TLS 的水平布局
  Widget _buildPortAndTlsRow(ThemeData theme) {
    return Row(
      // 关键：垂直居中对齐。
      // 左边是带边框的高输入框，右边是矮的开关，居中会让它们视觉上协调。
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. 端口输入框 (占据更多宽度)
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: widget.portController,
            decoration: AppInputStyles.outline(
              label: '端口 (Port)',
              prefixIcon: Icons.numbers,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
          ),
        ),

        // 中间间距
        Gaps.h16,

        // 2. TLS 开关 (紧凑布局)
        _buildTlsSwitch(theme),
      ],
    );
  }

  /// 构建纯净的 TLS 开关 (无 InkWell, 无额外触摸区)
  Widget _buildTlsSwitch(ThemeData theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.tlsNotifier,
      builder: (context, isTls, _) {
        return Row(
          // 使用 min AxisSize，让内容紧凑，不占满剩余空间
          // 配合父级 Row 的 CrossAxisAlignment.center 实现垂直居中
          mainAxisSize: MainAxisSize.min,
          children: [
            // 状态文字 (纯展示)
            Text(
              isTls ? 'HTTPS' : 'HTTP',
              style: TextStyle(
                color: isTls ? Colors.green : theme.colorScheme.onSurface,
                fontWeight: isTls ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),

            Gaps.h8,

            // 开关本体
            Transform.scale(
              scale: 0.8, // 保持小巧
              child: Switch(
                value: isTls,
                onChanged: (val) => widget.tlsNotifier.value = val,
                // 移除默认的边距，紧凑布局
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        );
      },
    );
  }
}
