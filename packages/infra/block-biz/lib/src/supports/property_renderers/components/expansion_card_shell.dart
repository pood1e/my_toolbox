import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../node_renderers/node_editor/node_editor_controller.dart';
import '../property_renderer.dart';

class ExpansionCardShell extends ConsumerStatefulWidget {
  final PropertyKey propertyKey;
  final PropertyRenderer renderer;
  final Widget child;
  final Widget expandedChild;
  final List<Widget> actions;

  const ExpansionCardShell({
    super.key,
    required this.propertyKey,
    required this.renderer,
    required this.child,
    required this.expandedChild,
    this.actions = const <Widget>[],
  });

  @override
  ConsumerState<ExpansionCardShell> createState() => _ExpansionCardShellState();
}

class _ExpansionCardShellState extends ConsumerState<ExpansionCardShell> {
  final ExpansibleController _controller = ExpansibleController();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (_isExpanded) ...widget.actions,
      IconButton(
        // 根据状态切换图标
        icon: Icon(
          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        ),
        onPressed: () {
          if (_isExpanded) {
            _controller.collapse();
          } else {
            _controller.expand();
          }
        },
      ),

      // 3. 删除按钮 (始终显示，位于 dropdown 按钮之后)
      IconButton(
        icon: const Icon(Icons.delete_outline),
        color: Theme.of(context).colorScheme.error,
        onPressed: () async {
          await ref
              .read(
                nodeEditorControllerProvider(
                  widget.propertyKey.nodeId,
                ).notifier,
              )
              .deleteProperty(widget.propertyKey.defId);
        },
      ),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacings.s,
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              controller: _controller,
              leading: Icon(widget.renderer.icon),
              title: Text(widget.renderer.name),

              // 监听展开状态变化，用于刷新图标
              onExpansionChanged: (bool expanded) {
                setState(() {
                  _isExpanded = expanded;
                });
              },

              // 自定义尾部区域
              trailing: _PropertyActions(actions: actions),
              children: [widget.expandedChild],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacings.l,
              AppSpacings.s,
              AppSpacings.l,
              AppSpacings.l,
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _PropertyActions extends StatelessWidget {
  final List<Widget> _actions;

  const _PropertyActions({required List<Widget> actions}) : _actions = actions;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacings.s,
    direction: Axis.horizontal,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: _actions,
  );
}
