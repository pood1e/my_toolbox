import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../meta/property_meta_service.dart';
import '../../../search/search_service.dart';
import '../property/property_card.dart';
import '../property/val_widget.dart';
import 'show_ref_picker.dart';

part 'reference_search.g.dart';

@riverpod
Stream<Set<PropertyId>> searchPropertyIdsByMetas(
  Ref ref,
  ReferenceSearchConfig config,
) async* {
  final srv = await ref.watch(searchServiceProvider.future);
  yield* srv.watchPropertyIdsByMetas(config.properties, config.excludes);
}

class ReferenceTile extends ConsumerWidget {
  final PropertyId _propertyId;
  final ActionsBuilder? _builder;

  const ReferenceTile({
    super.key,
    required PropertyId propertyId,
    ActionsBuilder? actionBuilder,
  }) : _propertyId = propertyId,
       _builder = actionBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objAsync = ref.watch(watchPropertyValProvider(_propertyId));
    final actions = _builder == null || objAsync.value == null
        ? <Widget>[]
        : _builder(objAsync.value!, () {
            Navigator.of(context).pop(objAsync.value);
          });
    return PropertyCardWidget(
      config: PropertyCardConfig(
        metaId: _propertyId.metaId,
        compactContent: objAsync.whenUI(
          data: (data) => PropertyValWidget(val: data!),
        ),
        actions: actions,
      ),
    );
  }
}

class ReferenceSearch extends ConsumerWidget {
  final ReferenceSearchConfig _config;

  const ReferenceSearch({super.key, required ReferenceSearchConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = ref.watch(searchPropertyIdsByMetasProvider(_config));
    return idsAsync.whenUI(
      data: (ids) => SingleChildScrollView(
        child: Column(
          children: ids
              .map(
                (id) => ReferenceTile(
                  propertyId: id,
                  actionBuilder: _config.actionBuilder,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
