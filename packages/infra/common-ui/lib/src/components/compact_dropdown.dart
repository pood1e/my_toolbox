import 'package:flutter/material.dart';

class CompactDropdown<T> extends StatefulWidget {
  final T value;
  final List<T> items;
  final String Function(T)? valueToLabel;
  final ValueChanged<T> onChanged;

  const CompactDropdown({
    super.key,
    required this.value,
    required this.items,
    this.valueToLabel,
    required this.onChanged,
  });

  @override
  State<CompactDropdown<T>> createState() => _CompactDropdownState<T>();
}

class _CompactDropdownState<T> extends State<CompactDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    final labelFunc = widget.valueToLabel ?? (t) => t.toString();
    return MenuAnchor(
      builder: (context, controller, child) => FilledButton.tonalIcon(
        onPressed: () => controller.open(),
        label: Text(labelFunc(widget.value)),
        icon: const Icon(Icons.arrow_drop_down),
        iconAlignment: IconAlignment.end,
      ),
      menuChildren: widget.items
          .map(
            (item) => MenuItemButton(
              onPressed: () {
                widget.onChanged(item);
              },
              child: Text(labelFunc(item)),
            ),
          )
          .toList(),
    );
  }
}
