import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../meta/property_meta_service.dart';
import '../../component_widget.dart';
import '../../property_common_ui.dart';

part 'property_card.freezed.dart';

@freezed
abstract class PropertyCardConfig with _$PropertyCardConfig {
  const factory PropertyCardConfig({
    required String metaId,
    Widget? content,
    Widget? compactContent,
    Future<void> Function()? onDeleted,
    @Default([]) List<Widget> actions,
  }) = _PropertyCardConfig;
}

class PropertyCardComponent extends ComponentWidget {
  @override
  ComponentBuilder get builder =>
      (cfg) => PropertyCardWidget(config: cfg);

  @override
  String get id => 'property_card';

  @override
  WidgetType get type => WidgetType.property;
}

class PropertyCardWidget extends ConsumerWidget {
  final PropertyCardConfig _config;

  const PropertyCardWidget({super.key, required PropertyCardConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.read(propertyMetaServiceProvider).getById(_config.metaId);
    List<Widget> tileContent = [];
    Widget? leading;
    if (meta is PropertyUiMeta) {
      leading = Icon(meta.icon);
      tileContent.add(Text(meta.name));
    } else {
      tileContent.add(Text(_config.metaId));
    }
    if (_config.compactContent != null) {
      tileContent.add(_config.compactContent!);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: leading,
            title: Wrap(
              spacing: AppSpacings.l,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: tileContent,
            ),
            trailing: Wrap(
              spacing: AppSpacings.s,
              children: [
                ..._config.actions,
                if (_config.onDeleted != null)
                  IconButton(
                    onPressed: _config.onDeleted,
                    icon: const Icon(Icons.delete),
                  ),
              ],
            ),
          ),
          if (_config.content != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacings.l,
                0,
                AppSpacings.l,
                AppSpacings.s,
              ),
              child: _config.content,
            ),
        ],
      ),
    );
  }
}
