/// 角色系统
class RoleSystem {
  /// role
  ///  - mandatory
  ///  - blueprint
  ///  - sugguested
  ///  _role
  ///  
}

enum RolePropertyLevel {
  mandatory, blueprint, sugguested
}



abstract class RolePropertyDefinition {
  String get propertyId;
  RolePropertyLevel get level;
}

abstract class RoleDefinition {

  // extends
  Set<String> get base;
}

abstract class NodeRoleStatus {
  Set<String> get validRoles;
  Set<String> get invalidRoles;
  Set<String> get sugguestedRoles;
}