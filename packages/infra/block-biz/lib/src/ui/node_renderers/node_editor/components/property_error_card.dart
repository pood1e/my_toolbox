import 'package:flutter/material.dart';

class PropertyErrorCard extends StatelessWidget {
  final String name;
  final String error;

  const PropertyErrorCard({super.key, required this.name, required this.error});

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      title: Text(name),
      subtitle: Text(error),
      trailing: const Icon(Icons.error_outline),
    ),
  );
}
