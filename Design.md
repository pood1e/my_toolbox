# 设计文档

## core

这个模块包含通用工具

- 日志：logger
- 国际化：intl
- 依赖注入：di & state = riverpod
- 对象定义辅助：object define = freezed
- 映射: auto_mappr

以下是dev_dependencies, 开发新包时, 按需添加

```yaml
dev_dependencies:
  build_runner: any
  # riverpod
  riverpod_generator: any
  custom_lint: any
  riverpod_lint: any
  # freezed
  freezed: any
  json_serializable: any
  # auto_mappr
  auto_mappr: any
```

## api

各个包对外暴露的接口定义, 协议定义等, 主要是给业务模块使用

### user-api

- 登陆状态
    - userId
    - role
- authencated dio

### data-api

- drift
- shared_perfences
-

### sync-api

## platform

### user-biz

用户鉴权功能实现

- 高级登陆状态
    - userId
    - role
    - accessToken(ws使用)
    - server
        - host
        - port
        - tls

- 登陆前处理
- 登陆后处理
- 登出/会话过期处理
