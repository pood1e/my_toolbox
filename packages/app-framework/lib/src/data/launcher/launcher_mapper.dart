import '../framework_database.dart';
import 'launcher_dto.dart';

extension AppUsageDtoToEntity on AppUsageDto {
  AppUsageEntity toEntity() {
    return AppUsageEntity(
      id: id,
      module: module,
      lastUsedAt: lastUsedAt,
      openCount: openCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension AppUsageEntityToDto on AppUsageEntity {
  AppUsageDto toDto() {
    return AppUsageDto(
      id: id,
      module: module,
      lastUsedAt: lastUsedAt,
      openCount: openCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}
