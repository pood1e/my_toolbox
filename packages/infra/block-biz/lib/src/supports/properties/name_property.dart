import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/icon_data.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/property_descriptor.dart';
import '../../domain/type_descriptor.dart';
import '../value_types/simple_text_type.dart';

class NameProperty extends PropertyDescriptor<String, String>
    implements PropertyDefaultEditConfig<String> {
  @override
  String get propertyId => '_name';

  @override
  String get defaultConfig => 'unnamed';

  @override
  String get name => 'name';

  @override
  TypeDescriptor<String, String> get typeDescriptor =>
      SimpleTextTypeDescriptor();

  @override
  IconData get icon => Symbols.id_card;
}
