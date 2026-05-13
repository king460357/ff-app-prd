---
模块: /admin/health — 系统健康度巡检面板
最后验证日期: 2026-05-10
最后验证 commit: 7b70f34（autoflow main 分支）
反推方法: 代码扫描（前端 + 后端契约 + migrations + git log），未读 PRD
---

> 📌 **本文档是从 autoflow 代码反推的"现状速查"**——
> 只写代码 100% 反推可信的事实 + 代码可见的设计模式。
> 不写业务 why / 用户场景——那是 PRD 的活。
> 写新需求前重新 pull autoflow + 检查最后验证日期是否过期 4 周+。

---

## 1. 模块定位

`/admin/health` — 系统级实时监控面板，4 Tab：**概览** / **配额** / **熔断器** / **Workflow**。

权限分级：
- `canViewServiceHealth`（admin / developer）→ 看所有 Tab
- `canControlWorkflow`（含 canForceCancel）→ 才能取消 Workflow / 强制熔断器开关

---

## 2. UI 单元清单

| 单元 | 用途 | 关键字段 |
|---|---|---|
| 顶部 KpiCard | 4 个指标卡 | running / totalErrors / peakQuota / breakerOpenCount |
| RunningProjectsSection | 当前在跑项目（可点击跳 /review/art-assets）| id / name / status / elapsed_ms / current_stage / lead_director_name |
| ErrorsLineChart | 24h 错误堆叠折线图（4 类）| timeout / activity / api_5xx / nlu，按整点 hour 分桶 |
| QuotaSection | 三 provider RPM 利用率 + 1h 5min 趋势 | provider（gemini/gpt/ark）/ rpm_current / rpm_limit / utilization / trend_5min |
| BreakerSection | 熔断器卡（CLOSED/HALF_OPEN/OPEN）+ 强制操作按钮 | provider / state / failure_rate_5m / manually_overridden |
| WorkflowsSection | Temporal RUNNING workflow 列表 + 24h 完成统计 | workflow_id / type / elapsed_ms / status |

---

## 3. 接口清单

| 路由 | 数据源 | 出参顶层 | 备注 |
|---|---|---|---|
| `/api/admin/health/projects` | core_pipeline.projects + workflow_checkpoint JSONB | { total, items[] } | — |
| `/api/admin/health/errors?since=24h` | feedback_history + project_action_log + debug_node_runs | { since, bucket_minutes:60, hours[24], by_kind, total } | 4 类聚合 |
| `/api/admin/health/quota` | **Mock**（待 #273 接入 Redis flowgate:rpm:*）| { items[], **_dev_mock: true**, source: "mock" } | 前端显示「⚠️ 开发数据」横幅 |
| `/api/admin/circuit-breaker` | **Mock**（后端 worker/circuit_breaker.py admin query 待上线）| { items[], **_dev_mock: true** } | 同上 |
| `/api/admin/circuit-breaker/[provider]` | 后端 override（待上线）| { new_state } | adminWriteEnabled=false 时 503 mock |
| `/api/admin/workflows?status=RUNNING&stats=1` | Temporal Visibility API | { items[], total, stats_24h, filters } | — |
| `/api/admin/workflows/[id]/cancel` | Temporal handle.cancel | { cancel_sent } | reason="manual cancel from health page" |
| `/api/admin/health/fallback-stats?window_hours=<1-168>` | gen_events.extras.fallback_meta | — | image_gen fallback 链统计 |

---

## 4. 数据表清单

| 表 | 关键字段 | 本模块用途 |
|---|---|---|
| `core_pipeline.projects` | id, name, status（starting/art_in_progress/art_review/running/approved）, lead_director_id, workflow_checkpoint(JSONB→.stage), deleted_at | 跑中项目列表（filter deleted_at IS NULL）|
| `core_pipeline.feedback_history` | applied_at（status='failed' AND applied_at >= since）| 错误来源 1 |
| `core_pipeline.project_action_log` | created_at, payload（action='stop' AND payload.reason 含 timeout/auto/expired）| 错误来源 2（timeout 类）|
| `core_pipeline.debug_node_runs` | created_at, error_message, error_kind（status='failed'）| 错误来源 3（api_5xx vs nlu 区分按 error_kind / message）|

---

## 5. ⚠️ 关键硬约束（PM 写新需求前必读）

| 约束 | 当前值 | 来源 file:line |
|---|---|---|
| 权限二级 | `canViewServiceHealth = isAdmin`（admin/developer），`canControlWorkflow = canForceCancel` | `role-capabilities.ts:57/59` |
| SWR 自动刷新 | 30 秒（仅 tab 非 hidden 时）| `_health-content.tsx:83` `REFRESH_30S` |
| KPI 健康评分 | breaker OPEN→30 / quota≥0.9 或 errors>50→60 / 其他→95 | `_health-content.tsx:236-241` |
| Mock 标记 | `_dev_mock=true` 时前端显示「⚠️ 开发数据」+ grey-out 写按钮 | `quota/route.ts:77` / `circuit-breaker/route.ts:91-92` |
| 24h bucket | 整点对齐（now.setMinutes(0,0,0)），24 个 1h 桶 | `errors/route.ts:39-57` |
| Workflow cancel 二次确认 | window.confirm + AlertDialog | `_health-content.tsx:849-868` |
| 错误业务化 | showError(errorType, {detail}) 优先读 j.error_type，兜底 "breaker_override_failed" | `_health-content.tsx:645-657` |
| Temporal UI 链接 | `NEXT_PUBLIC_TEMPORAL_UI` env + namespace encode | `_health-content.tsx:971-973` |
| Recharts 加载方式 | 整模块 dynamic import + skeleton（不能对子组件 dynamic 会破坏 displayName）| `health-charts.tsx:29-43` |

---

## 6. 🔗 线上已有的设计模式（新需求要遵守）

| 模式 | 现状 | 新需求设计要点 |
|---|---|---|
| **Mock 兜底 + flag 标记** | 后端未上线时 GET 返 `_dev_mock:true`，前端显示警告 banner + disable 写操作 | 加新依赖外部系统的接口要先上 mock 兜底，避免影响整页崩溃 |
| **权限二级化** | viewer（看）/ controller（操作）分开，UI 按 canXxx 渲染按钮 | 加危险操作（取消 / 重启 / 删除）走 controller 级权限 |
| **SWR independent keys** | 4 个 useSWR 独立 cache key（projects/errors/quota/breaker），Workflow Tab 条件化拉取 | 加新 Tab 数据源走独立 key + 条件化触发 |
| **Confirm dialog 不可逆操作** | 熔断器强制开关 + Workflow cancel 都用 AlertDialog 二次确认 | 加新不可逆操作必须二次确认 |
| **Recharts dynamic import** | 整模块延迟到客户端（ssr=false）+ skeleton 避免白屏 | 加图表类组件用相同模式 |
| **错误业务化（不裸 toast）**| ErrorBanner + showError(errorType, {detail}) 替代裸 toast.error | 新错误展示走 ErrorBanner，不要直接 toast |
| **整点对齐 24h bucket** | now.setMinutes(0,0,0) → 24 个 1h 桶 | 加新趋势图用相同对齐方式，避免桶错位 |
| **Cmd+K 全局快捷命令** | 注册刷新、跳 Tab 等 | 加新页面级动作可注册 |

---

## 7. 最近 3 个月活跃改动（PM 视角）

| commit / PR | PM 视角描述 |
|---|---|
| 59c0291 (#279) | Sprint 4 F4-3+4+5+6：服务健康页 P1 + Workflow 观测 + 权限差异化 + 移动端适配（最初实现）|
| 2dc178a (#292) | Mock route 假成功批量修复（_dev_mock 标记补齐）|
| 55b1997 (#293) | 前端 UX 批量优化（Cmd+K 注册 + dynamic import + skeleton 等 5 项 P1）|
| dea463b (#444) | admin observability 路由 + 持久侧边栏（B 阶段骨架，redirect 迁移计划）|

---

## 8. 📍 反推可能不准的点

- 配额 / 熔断器接口的真实数据源（当前是 mock）—— 待 #273 / `worker/circuit_breaker.py` admin query 上线后真实接口契约可能与 mock 略有差异
- "4 类错误"是否仅 timeout / activity / api_5xx / nlu —— 看到的是 `errors/route.ts:120-151` 的硬分类逻辑，未来扩展可能加新类
- KPI 健康评分阈值（30/60/95）和 breaker OPEN / quota≥0.9 / errors>50 的判定逻辑 —— 是 `_health-content.tsx:236-241` 的 magic number，可能后续会调
