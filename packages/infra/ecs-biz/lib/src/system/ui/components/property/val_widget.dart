import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../meta/property_meta_service.dart';
import '../../../value/value_service.dart';
import '../../component_widget.dart';

part 'val_widget.g.dart';

class ValCopmponetWidget implements ComponentWidget {
  @override
  ComponentBuilder get builder => throw UnimplementedError();

  @override
  String get id => 'val_widget';

  @override
  WidgetType get type => WidgetType.property;
}

@riverpod
Stream<PropertyVal?> watchPropertyVal(Ref ref, PropertyId propertyId) async* {
  final service = await ref.watch(valueServiceProvider.future);
  yield* service.watchValue(propertyId);
}

class ValWidget extends ConsumerWidget {
  final PropertyId _propertyId;

  const ValWidget({super.key, required PropertyId propertyId})
    : _propertyId = propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objAsync = ref.watch(watchPropertyValProvider(_propertyId));
    return objAsync.whenUI(data: (data) => PropertyValWidget(val: data!));
  }
}

class PropertyValWidget extends ConsumerWidget {
  final PropertyVal _val;

  const PropertyValWidget({super.key, required PropertyVal val}) : _val = val;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref
        .read(propertyMetaServiceProvider)
        .getById(_val.propertyId.metaId);
    if (meta is! PropertyValueMeta) {
      throw UnimplementedError();
    }
    final builder = ref
        .read(componentServiceProvider)
        .getDataTypeBuilder(meta.dataTypeId)!;
    return builder(_val.value);
  }
}
