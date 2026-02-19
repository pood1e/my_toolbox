/// 角色系统
class RoleSystem {
  /// role
  ///  - mandatory
  ///  - blueprint
  ///  - sugguested
  ///  _role
  ///
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