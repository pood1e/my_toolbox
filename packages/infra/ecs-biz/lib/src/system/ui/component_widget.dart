import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import 'components/basic/card_tile.dart';
import 'components/basic/list_widget.dart';
import 'components/basic/reuse_widget.dart';
import 'components/basic/text_input.dart';
import 'components/basic/text_view.dart';
import 'components/data_type/icon_data_view.dart';
import 'components/data_type/text_data_view.dart';
import 'components/node/node_editor.dart';
import 'components/node/node_tile.dart';
import 'components/page/node_list.dart';
import 'components/property/icon_editor.dart';
import 'components/property/name_editor.dart';
import 'impl/component_service_impl.dart';

part 'component_widget.g.dart';

typedef ComponentBuilder = Widget Function(dynamic config);

typedef PropertyComponentBuilder =
    Widget Function(String nodeId, dynamic config);

typedef ComponentFunc<C, T> =
    Future<T?> Function(BuildContext context, WidgetRef ref, C config);

enum WidgetType { basic, node, page, property }

abstract class ComponentWidget {
  String get id;

  WidgetType get type;

  ComponentBuilder get builder;
}

abstract class PropertyWidget {
  String get id;

  String get metaId;

  PropertyComponentBuilder get builder;
}

abstract class DataTypeWidget {
  String get id;

  bool get isDefault;

  String get dataTypeId;

  ComponentBuilder get builder;
}

abstract class ComponentAction<C, T> {
  // String get id;
  Future<T?> func(BuildContext context, WidgetRef ref, C config);
}

abstract class ComponentService {
  ComponentBuilder? getBuilder(WidgetType type, String id);

  PropertyComponentBuilder? getPropertyBuilder(String metaId, String id);

  ComponentBuilder? getDataTypeBuilder(String dataTypeId, [String? id]);

  // ComponentAction? getFunc(String id);
}

@Riverpod(keepAlive: true)
ComponentService componentService(Ref ref) => ComponentServiceImpl(
  components: [
    CardTileComponent(),
    ListComponent(),
    ReuseComponent(),
    TextInputComponent(),
    TextViewComponent(),

    NodeTileComponent(),

    NodeListComponent(),
    NodeEditorComponent(),
  ],
  propertyWidgets: [NamePropertyComponent(), IconPropertyComponent()],
  dataTypeWidgets: [IconDataView(), TextDataView()],
);
