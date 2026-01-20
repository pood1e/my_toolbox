import 'dart:convert';

import 'package:drift/drift.dart';

class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    try {
      return json.decode(fromDb) as Map<String, dynamic>;
    } catch (e) {
      // 容错处理：如果数据库存的数据坏了，返回空 Map
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return json.encode(value);
  }
}

class VectorConverter extends TypeConverter<List<double>, String> {
  const VectorConverter();

  @override
  List<double> fromSql(String fromDb) {
    // 数据库存的是 "[0.123, 0.456, ...]"
    return (jsonDecode(fromDb) as List).cast<double>();
  }

  @override
  String toSql(List<double> value) {
    return jsonEncode(value);
  }
}
