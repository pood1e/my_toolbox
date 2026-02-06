import 'package:app_core/object.dart';

import 'property.dart';
import 'stored_config.dart';

part 'property_config.freezed.dart';

@freezed
abstract class PropertyConfig with _$PropertyConfig {
  const factory PropertyConfig({
    required PropertyKey key,
    required List<StoredConfig> configs,
  }) = _PropertyConfig;
}
