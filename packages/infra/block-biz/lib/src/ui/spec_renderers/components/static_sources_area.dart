import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../domain/property_config.dart';

class StaticSourcesArea extends StatelessWidget {
  final Map<String, ProcessorComponent> _map;
  final Widget Function(String) _builder;
  final IconData? _leadingIcon;

  final void Function(String) _onDelete;
  final double _maxHeight;

  const StaticSourcesArea({
    super.key,
    required Map<String, ProcessorComponent> map,
    required Widget Function(String) builder,
    IconData? leadingIcon,
    required void Function(String) onDelete,
    required double maxHeight,
  }) : _map = map,
       _builder = builder,
       _leadingIcon = leadingIcon,
       _onDelete = onDelete,
       _maxHeight = maxHeight;

  @override
  Widget build(BuildContext context) {
    final keys = _map.keys.toList();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: _maxHeight),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: keys.length,
        itemBuilder: (_, index) {
          final key = keys[index];
          return StaticSourceTile(
            key: ValueKey(key),
            leadingIcon: _leadingIcon,
            builder: () => _builder(key),
            onDelete: () {
              _onDelete(key);
            },
          );
        },
      ),
    );
  }
}

class StaticSourceTile extends StatelessWidget {
  final VoidCallback _onDelete;
  final Widget Function() _builder;
  final IconData? _leadingIcon;

  const StaticSourceTile({
    super.key,
    required VoidCallback onDelete,
    required Widget Function() builder,
    IconData? leadingIcon,
  }) : _onDelete = onDelete,
       _builder = builder,
       _leadingIcon = leadingIcon;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: _leadingIcon != null
        ? Icon(_leadingIcon, size: AppSizes.iconSmall)
        : null,
    title: _builder(),
    trailing: IconButton(onPressed: _onDelete, icon: const Icon(Icons.remove)),
  );
}

