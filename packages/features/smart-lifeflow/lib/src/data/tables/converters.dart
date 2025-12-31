import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/lifeflow_shared.dart';

// --- 转换器 Stub ---
// 负责将复杂对象序列化为 JSON 字符串
/// SQL Type:  String (非空)
class RecurrenceJsonConverter extends TypeConverter<TaskRecurrence, String> {
  const RecurrenceJsonConverter();

  @override
  TaskRecurrence fromSql(String fromDb) {
    // 1. JSON String -> Map
    try {
      final jsonMap = json.decode(fromDb) as Map<String, dynamic>;
      // 2. Map -> Object
      return TaskRecurrence.fromJson(jsonMap);
    } catch (e) {
      // 如果数据库数据损坏，抛出异常或返回默认值
      // 建议：在开发阶段抛出异常以便发现问题
      throw Exception(
        'Failed to parse TaskRecurrence from DB: $fromDb, error: $e',
      );

      // 或者返回一个默认的安全值 (如果业务允许)
      // return const TaskRecurrence(frequency: RecurrenceFrequency.daily);
    }
  }

  @override
  String toSql(TaskRecurrence value) {
    // 1. Object -> Map -> JSON String
    return json.encode(value.toJson());
  }
}
