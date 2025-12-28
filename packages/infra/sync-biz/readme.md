这份文档详细回顾并总结了我们构建的 **离线优先 (Offline-First)** 同步系统。该设计基于 **Flutter (Riverpod + Drift)** 客户端与
**Spring Boot** 服务端，重点解决了时间不可靠、多端冲突、增量同步与流量优化等核心问题。

---

# 同步模块设计文档 (Synchronization Module)

## 1. 概述 (Overview)

本模块旨在实现一个健壮的、离线优先的数据同步系统。它允许用户在无网络环境下进行任意操作（增删改、统计），并在网络恢复后自动与服务器保持最终一致性。

### 核心设计原则

* **Offline-First**: 本地数据库是 UI 的唯一真理源 (Source of Truth)。UI 响应不依赖网络。
* **Server-Authoritative**: 服务器拥有最终裁决权（包括 ID 生成、时间戳修正、冲突仲裁）。
* **Unified Batch Sync**: 推送 (Push) 与拉取 (Pull) 合并为单一原子操作，支持增量同步。
* **Trusted Time**: 通过混合时钟算法解决客户端时间被篡改或不准的问题。

---

## 2. 时间服务 (Time Service)

为了解决“用户修改系统时间”导致的数据乱序和安全问题，我们实现了一个独立于系统墙上时钟（Wall Clock）的单调时间服务。

### 2.1 架构：TimeProvider

客户端通过 `TimeProvider` 获取当前时间，而非直接使用 `DateTime.now()`。

* **内存态 (Hot)**: `ServerBaseTime + Stopwatch.elapsed`。利用 CPU 单调计时器，抗系统时间修改。
* **持久态 (Cold/Restart)**: `Anchor (Server - Uptime) + SystemUptime`。
* **重启检测 (Reboot Check)**: 绑定 **Boot ID** (`/proc/sys/kernel/random/boot_id` 或 Native API)。若 Boot ID
  变更，强制重新联网校准。

### 2.2 Riverpod 集成

`TimeProvider` 生命周期跟随 `remoteServerProvider`。当用户切换服务器地址时，时间服务自动重置并重新校准。

### 2.3 双时间字段设计

数据库中严格区分两种时间语义：

| 字段名                     | 类型           | 来源                     | 用途              | 备注                  |
|:------------------------|:-------------|:-----------------------|:----------------|:--------------------|
| **`updated_at`**        | DateTime     | **客户端 (TimeProvider)** | 业务展示、LWW 冲突比较   | 可能被服务端纠错 (Clamping) |
| **`server_updated_at`** | Long (Int64) | **服务端**                | 增量同步游标 (Cursor) | 客户端只读，上传时忽略         |

---

## 3. 数据策略矩阵 (Strategy Matrix)

根据业务属性，将数据分为两大类，采用不同的表结构与冲突策略。

### 类型 A: 状态/文档型 (LWW)

**适用**: 开关、配置、笔记、用户资料。

* **表结构**:
* `content`: 业务数据
* `is_dirty` (Bool): **true** 表示本地有未上传修改
* `shadow_content` (Text, Optional): 用于笔记的三路合并
* **冲突策略**: **Last Write Wins (LWW)**
* 基于 `updated_at` 比较。
* **Client Protection**: 如果 Pull 回来的数据与本地 Dirty 数据冲突，优先保留本地 (Client Wins)，等待下次 Push。
* **Notes Special**: 使用 `diff-match-patch` 进行文本合并，失败则创建冲突副本。

### 类型 B: 累加/统计型 (Delta)

**适用**: App 打开次数、步数、积分。

* **表结构**:
* `total_count`: 展示基数
* `unsynced_increment`: **待上传增量** (如 +5)
* `locked_delta`: 发送中的锁定值
* `current_tx_id`: **幂等事务 ID**
* **冲突策略**: **Delta Merging**
* 客户端发送增量，服务端执行 `Total += Delta`。
* 通过 `tx_id` 保证网络超时重试时不会重复累加。

---

## 4. 同步流程详解 (Sync Loop)

同步通过单一接口 `POST /api/v1/sync` 完成。

### 步骤 1: 本地写入 (Local Write)

* **时间清洗**: DAO 层调用 `TimeProvider.now`。若时间严重超前（>容忍阈值），客户端预先修正为当前时间。
* **标记**: 置 `is_dirty = true` 或 `unsynced_increment += 1`。

### 步骤 2: 构建请求 (Snapshot & Push)

* **快照**: 锁定统计数据的增量 (`unsynced` -> `locked`)，生成 `tx_id`。
* **Payload**:
  ```json
  {
    "cursor": 1001,  // last_known_server_updated_at
    "changes": [
      { "type": "NOTE", "id": "A", "data": "...", "updatedAt": ... },
      { "type": "STAT", "id": "B", "delta": 5, "txId": "uuid..." }
    ]
  }
  ```

### 步骤 3: 服务端处理 (Server Logic)

* **安全防御 (Time Clamping)**:
* `StorageTime = MIN(ClientTime, ServerNow + 1_Minute)`。
* 防止“未来时间戳攻击”锁定数据。
* **处理 LWW**: 对比 DB 时间，新则覆盖，旧则忽略。
* **处理 Delta**: 检查 `tx_id` 去重，执行原子累加。
* **拉取更新 (Fetch)**: 查询所有 `server_updated_at > cursor` 的数据。

### 步骤 4: 响应 (Response)

服务端返回 **Ack + Changes** 结构以节省流量。

```json
{
    "serverTime": 2005,
    // 新游标
    "ackedIds": [
        "A"
    ],
    // 省流：表示服务器原样接受，未发生修改
    "changes": [
        // 包含回声(被服务器修改过的) 或 他人的修改
        {
            "id": "B",
            "totalCount": 100,
            "serverUpdatedAt": 2005
        },
        {
            "id": "C",
            "content": "New Note",
            "serverUpdatedAt": 2005
        }
    ]
}
```

### 步骤 5: 本地回写 (Reconcile)

**原则：不信任本地发送回调，只信任 Server 返回的数据。**

1. **处理 Ack**:

* 将 `ackedIds` 对应数据的 `is_dirty` 置为 `false`，更新 `server_updated_at`。
* 对于统计数据，扣减 `locked_delta`。

2. **处理 Changes (Merge)**:

* **脏数据保护**: 如果本地对应数据是 `is_dirty` (冲突)：
    * **内容一致**: 视为同步成功，清除脏标记。
    * **内容不一致**: **忽略服务器数据** (保留本地修改)，等待下次 Push 覆盖。
    * *(笔记类触发三路合并或副本逻辑)*。
* **非脏数据**: 直接 overwrite 本地数据，更新游标。

---

## 5. 安全与防御 (Security & Defense)

### 5.1 纵深防御体系

1. **第一道防线 (Header Check)**:

* 请求头携带 `X-Client-Time`。
* 服务端检测偏差 > 5分钟 -> 返回 `412` -> 客户端弹窗提示用户校准系统时间。

2. **第二道防线 (Client Sanitization)**:

* DAO 层写入时，若系统时间 > TimeProvider 时间，自动降级使用 TimeProvider。

3. **第三道防线 (Server Cap-on-Write)**:

* 入库时强制封顶未来时间，确保数据库内永远不会出现“明天的修改”。

### 5.2 流量优化

1. **Gzip**: 全局开启 HTTP Gzip 压缩。
2. **Ack 分离**: 服务器未修改的数据只回传 ID，减少 90% 下行流量。

---

## 6. 客户端模块结构 (Riverpod)

```
lib/
├── core/
│   ├── time/
│   │   ├── time_service.dart      # 纯 Dart 逻辑 (Stopwatch, BootID)
│   │   └── time_controller.dart   # Riverpod Provider (生命周期管理)
│   └── database/
│       └── schema.dart            # Drift 表定义 (SyncBase, LwwTable...)
├── features/
│   ├── sync/
│   │   ├── sync_service.dart      # 负责 API 调用与 Reconcile 逻辑
│   │   └── sync_coordinator.dart  # 监听 DB Stream, 触发防抖同步
```

---

## 7. 总结

本设计通过 **TimeProvider** 解决了移动端最棘手的时间信任问题，通过 **Delta/LWW 分离策略** 解决了复杂业务的数据一致性，通过
**Ack 机制** 实现了极低的流量消耗。这是一个可扩展、高可用的工业级同步方案。