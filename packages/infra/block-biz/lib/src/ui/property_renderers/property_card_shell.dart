import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../domain/property.dart';
import '../node_renderers/node_editor/node_editor_controller.dart';
import 'property_renderer.dart';

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
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            // Row 1: Header + (Optional Content) + Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 8,
              children: [
                _PropertyBasicInfo(name: _renderer.name, icon: _renderer.icon),
                Expanded(child: isHorizontal ? _child : const Spacer()),
                _PropertyActions(actions: actions),
              ],
            ),
            if (!isHorizontal) _child,
          ],
        ),
      ),
    );
  }
}

class _PropertyBasicInfo extends StatelessWidget {
  final String _name;
  final IconData _icon;

  const _PropertyBasicInfo({required String name, required IconData icon})
    : _name = name,
      _icon = icon;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    direction: Axis.horizontal,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Icon(_icon, color: Theme.of(context).colorScheme.primary),
      Text(
        _name,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _PropertyActions extends StatelessWidget {
  final List<Widget> _actions;

  const _PropertyActions({required List<Widget> actions}) : _actions = actions;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    direction: Axis.horizontal,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: _actions,
  );
}
