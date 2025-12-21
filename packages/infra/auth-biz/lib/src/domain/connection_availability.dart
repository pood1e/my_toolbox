enum ConnectionAvailability {
  guest, // 访客/未登录
  verifying, // 验证中 (刚启动或刚登录)
  active, // 活跃 (Token 有效，网络正常)
  offline, // 离线 (Token 应该有效，但没网)
  expired, // 过期 (服务端返回 401，需要重登)
}
