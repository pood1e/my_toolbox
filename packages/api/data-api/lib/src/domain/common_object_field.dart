abstract class IdObject {
  List<dynamic> get primaryKey;
}

abstract class SoftDeleteObject {
  int? get deletedAt;
}

abstract class AuditObject {
  int get createdAt;

  int get updatedAt;
}
