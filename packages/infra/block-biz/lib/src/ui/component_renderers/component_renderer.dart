import 'package:flutter/material.dart';

import '../../domain/property.dart';

enum RendererType { widget, dialog }

sealed class ComponentRenderer {
  String get id;

  RendererType get type;
}

class ProcessorWidget extends ComponentRenderer {
  @override
  final String id;

  @override
  RendererType get type => RendererType.widget;
  final Widget Function(
    dynamic config,
    ValueChanged<dynamic> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
    VoidCallback onCancel,
  )
  builder;

  ProcessorWidget({required this.id, required this.builder});
}

class ProcessorDialog extends ComponentRenderer {
  @override
  final String id;

  @override
  RendererType get type => RendererType.dialog;

  final Future<dynamic> Function(BuildContext context, dynamic config)
  showDialog;

  ProcessorDialog({required this.id, required this.showDialog});
}

class TransformerDialog extends ComponentRenderer {
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
