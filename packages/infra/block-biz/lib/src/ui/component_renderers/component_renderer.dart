import 'package:flutter/material.dart';

import '../../domain/property.dart';

enum RendererType { widget, dialog }

sealed class ComponentRenderer {
  String get id;

  RendererType get type;
}

class ProcessorWidget<T> extends ComponentRenderer {
  @override
  final String id;

  @override
  RendererType get type => RendererType.widget;
  final Widget Function(
    T config,
    ValueChanged<T> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
  )
  builder;

  ProcessorWidget({required this.id, required this.builder});
}

class ProcessorDialog<T> extends ComponentRenderer {
  @override
  final String id;

  @override
  RendererType get type => RendererType.dialog;

  final Future<dynamic> Function(BuildContext context, dynamic config)
  showDialog;

  ProcessorDialog({required this.id, required this.showDialog});
}

class TransformerDialog<T> extends ComponentRenderer {
  @override
  final String id;

  @override
  RendererType get type => RendererType.dialog;

  final Future<dynamic> Function(
    BuildContext context,
    dynamic config,
    PropertyKey currentKey,
    String currentSpec,
  )
  showRefPicker;

  TransformerDialog({required this.id, required this.showRefPicker});
}
