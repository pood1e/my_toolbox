/// 任务获取 (Polling/Listening)： 从数据库或队列中获取待执行的任务。
/// 调度逻辑 (Scheduling Logic)：
/// - 时间触发： 如果是 Cron Job，判断是否到了执行时间。
/// - 依赖检查： 检查任务的前置条件（Upstream）是否完成（例如 Airflow）。
/// - 优先级排序： 决定哪个任务先跑。
/// 资源分配 (Resource Management)： 检查是否有空闲的 Worker，或者 Worker 的资源（CPU/内存）是否足够。
/// 分发 (Dispatching)： 将任务指派给特定的 Worker 或放入就绪队列等待 Worker 领取。
/// 故障处理 (Failover)： 如果 Worker 挂了，Scheduler 负责将任务重新调度给其他 Worker。
abstract class ComputeScheduler {
  Future<void> notifyDirty();
}
