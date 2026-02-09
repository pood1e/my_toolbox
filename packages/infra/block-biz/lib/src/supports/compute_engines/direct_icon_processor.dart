import 'package:app_core/object.dart';
import 'package:flutter/cupertino.dart';

import '../../domain/compute_engine.dart';
import '../value_types/icon_data_type.dart';

part 'direct_icon_processor.freezed.dart';
part 'direct_icon_processor.g.dart';

@freezed
abstract class DirectIcon with _$DirectIcon {
  const factory DirectIcon({@IconDataConverter() required IconData data}) =
      _DirectIcon;

  factory DirectIcon.fromJson(Map<String, dynamic> json) =>
      _$DirectIconFromJson(json);
}

class DirectIconProcessor implements Processor<DirectIcon, IconData> {
  @override
  DirectIcon fromDb(Map<String, dynamic> value) => DirectIcon.fromJson(value);

  @override
  String get id => 'direct_icon';

  @override
  Future<IconData> process(DirectIcon config) async => config.data;

  @override
  Map<String, dynamic> toDb(DirectIcon value) => value.toJson();

  @override
  String get typeId => 'icon';

  @override
  String? validate(DirectIcon value) => null;
}
