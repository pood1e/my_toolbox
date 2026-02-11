import 'package:flutter/material.dart';

import '../../domain/compute_engine.dart';
import '../value_types/icon_data_type.dart';

class SimpleIconProcessor implements Processor<IconData, IconData> {
  @override
  IconData fromDb(Map<String, dynamic> value) => value.toIconData()!;

  @override
  String get id => 'simple_icon';

  @override
  Future<IconData> process(IconData config) async => config;

  @override
  Map<String, dynamic> toDb(IconData value) => value.toJson();

  @override
  String get typeId => 'icon';

  @override
  String? validate(IconData value) => null;
}
