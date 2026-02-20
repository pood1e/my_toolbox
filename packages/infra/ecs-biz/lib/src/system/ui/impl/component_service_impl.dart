import '../component_widget.dart';

class ComponentServiceImpl implements ComponentService {
  final Map<(WidgetType, String), ComponentBuilder> _map;
  final Map<(String, String), PropertyComponentBuilder> _propertyMap;

  ComponentServiceImpl({
    required List<ComponentWidget> components,
    required List<PropertyWidget> propertyWidgets,
  }) : _map = {
         for (final widget in components)
           (widget.type, widget.id): widget.builder,
       },
       _propertyMap = {
         for (final widget in propertyWidgets)
           (widget.metaId, widget.id): widget.builder,
       };

  @override
  ComponentBuilder? getBuilder(WidgetType type, String id) => _map[(type, id)];

  @override
  ComponentAction<dynamic, dynamic>? getFunc(String id) {
    // TODO: implement getFunc
    throw UnimplementedError();
  }

  @override
  PropertyComponentBuilder? getPropertyBuilder(String metaId, String id) =>
      _propertyMap[(metaId, id)];
}
