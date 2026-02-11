import 'package:flutter/material.dart';

import '../property_editor_definition.dart';

class PropertyCardShell extends StatelessWidget {
  final IconData icon;
  final String name;
  final PropertyViewLayout layout;
  final Widget content;
  final List<Widget> actions;
  final VoidCallback? onDelete;

  const PropertyCardShell({
    super.key,
    required this.icon,
    required this.name,
    required this.layout,
    required this.content,
    required this.actions,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isHorizontal = layout == PropertyViewLayout.horizontal;
    List<Widget> acs = actions;
    if (onDelete != null) {
      acs = [
        ...actions,
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          color: Theme.of(context).colorScheme.error,
        ),
      ];
    }
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                _PropertyBasicInfo(name: name, icon: icon),
                Expanded(child: isHorizontal ? content : const Spacer()),
                _PropertyActions(actions: acs),
              ],
            ),
            if (!isHorizontal) content,
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
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, direction: Axis.horizontal, children: _actions);
}
