/// 提供一套模板
///

abstract class PropertyTemplate {
  String get id;

  Map<String, dynamic> get defaultConfigMap;
}

abstract class PropertyTemplateService {
  Future<void> usePropertyTemplate(String templateId);
}


