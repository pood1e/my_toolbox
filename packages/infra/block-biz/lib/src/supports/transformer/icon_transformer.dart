import 'package:flutter/material.dart';

import '../../domain/compute_engine.dart';

class IconTransformer implements Transformer<IconData, void, IconData> {
  @override
  void fromDb(Map<String, dynamic> value) {}

  @override
  String get id => 'icon_direct';

  @override
  String get sTypeId => 'icon';

  @override
  String get tTypeId => 'icon';

  @override
  Map<String, dynamic> toDb(void value) => {};

  @override
  Future<IconData> transform(IconData source, void config) async => source;

  @override
  String? validate(void config) => null;
}
