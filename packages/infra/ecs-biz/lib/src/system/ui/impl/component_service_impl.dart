import '../component_widget.dart';

class ComponentServiceImpl implements ComponentService {
  final Map<(WidgetType, String), ComponentWidget> _map;

  ComponentServiceImpl({required List<ComponentWidget> widgets})
    : _map = {for (final widget in widgets) (widget.type, widget.id): widget};

  @override
  ComponentBuilder? getBuilder(WidgetType type, String id) =>
      _map[(type, id)]?.builder;

  @override
  ComponentAction<dynamic, dynamic>? getFunc(String id) {
    // TODO: implement getFunc
    throw UnimplementedError();
  }
}
