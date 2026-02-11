import 'package:flutter/material.dart';

class PropertyLoadingCard extends StatelessWidget {
  final String name;

  const PropertyLoadingCard({super.key, required this.name});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(name),
      trailing: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}
