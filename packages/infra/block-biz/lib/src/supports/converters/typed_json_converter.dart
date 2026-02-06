import 'dart:convert';

import 'string_converter.dart';

abstract class TypedJsonConverter<T> {
  T decode(Map<String, dynamic> config);

  Map<String, dynamic> encode(T t);
}

class TypedStringConverter<T> implements StringConverter<T> {
  final TypedJsonConverter<T> _converter;

  TypedStringConverter({required TypedJsonConverter<T> converter})
    : _converter = converter;

  @override
  T decode(String? config) => _converter.decode(jsonDecode(config!));

  @override
  String? encode(T config) => jsonEncode(_converter.encode(config));
}
