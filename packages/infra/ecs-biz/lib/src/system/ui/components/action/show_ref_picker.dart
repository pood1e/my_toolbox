import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../meta/property_meta_service.dart';
import '../../../value/value_service.dart';
import '../../component_widget.dart';
import 'reference_search.dart';

part 'show_ref_picker.freezed.dart';

typedef ActionsBuilder =
    List<Widget> Function(PropertyVal, void Function() onSelectedExit);

@freezed
abstract class ReferenceSearchConfig with _$ReferenceSearchConfig {
  const factory ReferenceSearchConfig({
    required Set<String> properties,
    required Set<PropertyId> excludes,
    ActionsBuilder? actionBuilder,
  }) = _ReferenceSearchConfig;
}

class RefPicker implements ComponentAction<ReferenceSearchConfig, void> {
  const RefPicker();

  @override
  Future<void> func(
    BuildContext context,
    WidgetRef ref,
    ReferenceSearchConfig config,
  ) => showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacings.card),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [ReferenceSearch(config: config)],
          ),
        ),
      ),
    ),
  );
}
