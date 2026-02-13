import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../node_renderers/node_editor/node_editor_controller.dart';
import '../property_renderer.dart';

class PropertyCardShell extends ConsumerWidget {
  final PropertyKey _propertyKey;
  final PropertyViewLayout _layout;
  final PropertyRenderer _renderer;
  final Widget _child;
  final List<Widget> _actions;
  final bool _showDelete;

  const PropertyCardShell({
    super.key,
    required PropertyKey propertyKey,
    PropertyViewLayout layout = PropertyViewLayout.horizontal,
    required PropertyRenderer renderer,
    required Widget child,
    List<Widget> actions = const <Widget>[],
    bool showDelete = true,
  }) : _propertyKey = propertyKey,
       _layout = layout,
       _renderer = renderer,
       _child = child,
       _actions = actions,
       _showDelete = showDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHorizontal = _layout == PropertyViewLayout.horizontal;
    List<Widget> actions = _actions;
    if (_showDelete) {
      actions = [
        ...actions,
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await ref
                .read(
                  nodeEditorControllerProvider(_propertyKey.nodeId).notifier,
                )
                .deleteProperty(_propertyKey.defId);
          },
          color: Theme.of(context).colorScheme.error,
        ),
      ];
    }
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacings.s,
        children: [
          // Row 1: Header + (Optional Content) + Actions
          ListTile(
            // contentPadding: EdgeInsets.zero,
            leading: Icon(_renderer.icon),
            title: Row(
              spacing: AppSpacings.xl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_renderer.name),
                isHorizontal
                    ? Expanded(child: _child)
                    : const SizedBox.shrink(),
              ],
            ),
            trailing: _PropertyActions(actions: actions),
          ),
          if (!isHorizontal)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacings.l,
                AppSpacings.s,
                AppSpacings.l,
                AppSpacings.l,
              ),
              child: _child,
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
