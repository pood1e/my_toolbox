import 'package:app_core/object.dart';

import '../../config/config_service.dart';
import '../property_meta_service.dart';

part 'name_meta.freezed.dart';
part 'name_meta.g.dart';

@freezed
abstract class NameConfig with _$NameConfig {
  const factory NameConfig({required String text}) = _NameConfig;

  factory NameConfig.fromJson(Map<String, dynamic> json) =>
      _$NameConfigFromJson(json);
}

class NameMeta extends PropertyMeta with PropertyConfigMeta<NameConfig> {
  @override
  String get metaId => '_name';

  @override
  NameConfig fromDb(Map<String, dynamic> cfg) => NameConfig.fromJson(cfg);

  @override
  Map<String, dynamic> toDb(NameConfig cfg) => cfg.toJson();
}
