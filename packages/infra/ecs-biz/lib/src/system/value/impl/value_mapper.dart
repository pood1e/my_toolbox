import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import '../value_service.dart';

extension ValueMapper on PropertyValEntity {
  PropertyVal? toPropertyVal(StorageType storageType, DataType type) {
    dynamic rawDbValue;
    switch (storageType) {
      case StorageType.bool:
        rawDbValue = valBool;
        break;
      case StorageType.int:
        rawDbValue = valInt;
        break;
      case StorageType.real:
        rawDbValue = valReal;
        break;
      case StorageType.text:
        rawDbValue = valText;
        break;
      case StorageType.str:
        rawDbValue = valStr;
        break;
      case StorageType.json:
        rawDbValue = valJson;
        break;
    }

    dynamic runtimeValue = rawDbValue;
    if (rawDbValue != null) {
      runtimeValue = type.fromDb(rawDbValue);
    }

    return PropertyVal(
      propertyId: PropertyId(nodeId: nodeId, metaId: metaId),
      value: runtimeValue,
      status: status,
      extra: extra,
    );
  }
}
