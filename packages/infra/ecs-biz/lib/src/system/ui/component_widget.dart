import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import 'components/basic/card_tile.dart';
import 'components/basic/list_widget.dart';
import 'components/basic/reuse_widget.dart';
import 'components/basic/text_input.dart';
import 'components/basic/text_view.dart';
import 'components/node/node_tile.dart';
import 'components/page/node_editor.dart';
import 'components/page/node_list.dart';
import 'impl/component_service_impl.dart';

part 'component_widget.g.dart';

typedef ComponentBuilder =
    Widget Function(BuildContext context, WidgetRef ref, dynamic config);

typedef ComponentFunc<C, T> =
    Future<T> Function(BuildContext context, WidgetRef ref, C config);

enum WidgetType { basic, property, node, page }

abstract class ComponentWidget<C> {
  String get id;

  WidgetType get type;

  ComponentBuilder get builder;
}

abstract class ComponentAction<C, T> {
  String get id;

  ComponentFunc<C, T> get func;
}

abstract class ComponentService {
  ComponentBuilder? getBuilder(WidgetType type, String id);

  ComponentAction? getFunc(String id);
}

@Riverpod(keepAlive: true)
ComponentService componentService(Ref ref) => ComponentServiceImpl(
  widgets: [
    CardTileComponent(),
    ListComponent(),
    ReuseComponent(),
    TextInputComponent(),
    TextViewComponent(),

    NodeTileComponent(),

    NodeListComponent(),
    NodeEditorComponent(),
  ],
);
