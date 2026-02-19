import 'package:flutter/material.dart';

/// store aspect

abstract class Node {
  String get id;
}

mixin HasRoles on Node {
  List<String> get roles;
}

abstract class Property {
  String get id;
}

// if has value
// call value service .xx()
abstract class ValueService {
  
}

// ns
mixin HasConfig on Property {
  // config
}

enum ValueSource {
  compute, defined, config
}

// ns
mixin HasValue on Property {
  // value type
  
  // can be ref

  // deps
}


// compute value table : property - [value]
mixin ComputeValue on Property {
  // ComputeGraphConfig
}

enum ComputeType {
  source, transformer, aggregator
}

abstract class ComputeConfig {
  String get id;
  ComputeType get type;
  dynamic get config;

  String? get next;
  ComputeType? get nextType;
}




enum CfgRecordType { single, multi }

abstract class PropertyCfg {

}

abstract class CfgSchema {

}


abstract class Field {
  String get id;

  /// --- database aspect ---
  String get configKey;
  /// ref / static
  bool get hasRef;
  /// single / multi
  CfgRecordType get recordType;

  /// --- ui aspect ---
  bool get show;
  /// if show
  /// from inputs : config
  /// or build
}

abstract class SpecField {
  String get fieldId;


}

abstract class Spec {
  String get id;

  // data aspect


  // ui aspect

}


abstract class CfgField {
  /// configKey
  String get configKey;

  /// ref / static
  bool get hasRef;

  /// single / multi
  CfgRecordType get recordType;
  /// basic validate
}

abstract class SpecFieldDef {
  /// spec field validate
  ///
}

abstract class CfgSpec {
  List<CfgField> get fields;
}

enum WidgetType {
  input, field, spec, property, node
}

abstract class RegistryWidget<C> {
  String get id;
  WidgetType get type;
  Widget build(C config);
}

abstract class SpecFieldUIAspect {

}