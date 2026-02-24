import '../component_widget.dart';

class ComponentServiceImpl implements ComponentService {
  final Map<(WidgetType, String), ComponentBuilder> _map;
  final Map<(String, String), PropertyComponentBuilder> _propertyMap;

  final Map<String, ComponentBuilder> _defaultTypeMap;
  final Map<(String, String), ComponentBuilder> _dataTypeMap;

  ComponentServiceImpl({
    required List<ComponentWidget> components,
    required List<PropertyWidget> propertyWidgets,
    required List<DataTypeWidget> dataTypeWidgets,
  }) : _map = {
         for (final widget in components)
           (widget.type, widget.id): widget.builder,
       },
       _propertyMap = {
         for (final widget in propertyWidgets)
           (widget.metaId, widget.id): widget.builder,
       },
       _dataTypeMap = {
         for (final widget in dataTypeWidgets)
           (widget.dataTypeId, widget.id): widget.builder,
       },
       _defaultTypeMap = {
         for (final widget in dataTypeWidgets)
           if (widget.isDefault) widget.dataTypeId: widget.builder,
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

  @override
  ComponentBuilder? getDataTypeBuilder(String dataTypeId, [String? id]) {
    if (id == null) {
      return _defaultTypeMap[dataTypeId];
    }
    return _dataTypeMap[(dataTypeId, id)];
  }
}
