# features

- graph视图
- 定期提醒
- 待办(饮食规划, 日常事务)
- 微观流程编排(食谱, 健身动作, 番茄钟)
- 库存
- 计算(基于库存和饮食规划和食谱计算购买清单)
- 双链笔记

# ARCHITECTURE

能确定的是有一个基本block, 有一些预置模板, 用户可添加模板 

- 同步策略:  LWW


## tables

entity(insertOnly)
- id: nanoId

component(lww)
- id: nanoId
- entityId: ref(entity, id)
- type: int8
- constraintType: int8?
- allowRef: bool(true)

field(lww)
- id: nanoId
- componentId: ref(component, id)
- key: varchar(64)
- config: json?
- data: text?
- type: int8
- collectionType: int8?
- cacheDirty: bool(false)

field-ref(lww)
- src: ref(field, id)
- dst: ref(field, id)
- rank: int
- failed: bool(false)

## System

我们基本只实现基本组件, 提供组合的渠道, 让用户自行组合

### basic input

- text: 文本输入
- number: 数值, 可配类型, 可以限制范围
- status: 状态机, 可以配置状态流转
- scale: 度量, 一般是高10, 中5, 低1, 这种文字和数字常量的map
- timer: 计时器, 可以配置
- date: 日期
- image: 图片
- code: 代码块
- rich_text: 富文本

### basic render

- browser : 文件夹视图
  - list : 列表
  - grid : 表格

- document: 文档视图
  - readonly: 只读
  - editable: 可编辑

- flow : 流程视图
  - step : 每步一个大卡片
  - overview : 总览

- graph

### template

- 物质
  - name: text
  - icon(optional): image

- 食物
  - name: text
  - icon(optional): image
  - 成分(optional): list[物质, 含量]
  - 大致价格(optional)

- 库存: list[入库时间, 食物, 剩余数量/重量, 剩余过期天数, 价格]
- 饮食计划: list[date, 餐次, 多个食谱/多个食物, 数量/重量]

- 食谱
  - name: text
  - icon(optional): image
  - 配料(optional): list[食物 , 数量/重量]
  - 合成价格
  - 合成成分
  - 步骤

- 每日营养成分分析
- 每日账单
- 单个健身动作
- 健身计划
- 健身动作组合

- 部署步骤
...

# block
## id

nanoId

## type

inner
- title
- image
- richtext
- text
- reminder
- timer

## content

json

## properties

json

# property

## id

nanoId

## type

- number
- status
- aggregate
- rrule
- date


## mess

schema = entity + [components]

