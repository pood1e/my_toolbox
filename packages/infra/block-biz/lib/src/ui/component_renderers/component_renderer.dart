import 'package:flutter/material.dart';

abstract class ComponentRenderer<T> {
  String get id;

  Widget build(
    T config,
    ValueChanged<T> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
  );
}

abstract class ProcessorRenderer<T> extends ComponentRenderer<T> {}
