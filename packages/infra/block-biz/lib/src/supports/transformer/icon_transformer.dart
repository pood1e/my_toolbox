import 'package:flutter/material.dart';

import '../../domain/compute_engine.dart';

class IconTransformer implements Transformer<IconData, void, IconData> {
  @override
  void fromDb(value) {}

  @override
  String get id => 'icon_direct';

  @override
  String get sTypeId => 'icon';

  @override
  String get tTypeId => 'icon';

  @override
  dynamic toDb(void value) => null;

  @override
  Future<IconData> transform(IconData source, void config) async => source;

  @override
  String? validate(void config) => null;

  @override
  String? keyValidate(String config) => null;
}
