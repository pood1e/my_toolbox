import 'package:flutter/material.dart';

class SelectIconButton extends StatelessWidget {
  final VoidCallback? _onPressed;
  final IconData _icon;
  final bool _selected;

  const SelectIconButton({
    super.key,
    VoidCallback? onPressed,
    required IconData icon,
    bool selected = false,
  }) : _onPressed = onPressed,
       _icon = icon,
       _selected = selected;

  @override
  Widget build(BuildContext context) => _selected
      ? IconButton.filledTonal(onPressed: _onPressed, icon: Icon(_icon))
      : IconButton(onPressed: _onPressed, icon: Icon(_icon));
}
