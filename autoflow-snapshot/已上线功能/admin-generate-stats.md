---
模块: /admin/generate-stats — 生成质量统计后台
最后验证日期: 2026-05-10
最后验证 commit: 7b70f34（autoflow main 分支）
反推方法: 代码扫描（前端 + 后端契约 + migrations + git log），未读 PRD
---

> 📌 **本文档是从 autoflow 代码反推的"现状速查"**——
> 只写代码 100% 反推可信的事实 + 代码可见的设计模式。
> **不写**业务 why / 用户场景 / 设计动机——那是 PRD 的活。
> 写新需求前重新 pull autoflow + 检查本文最后验证日期是否过期 4 周+。

---

## 1. 模块定位

`/admin/generate-stats` — 视频生成质量数据统计后台，按 **用户 / 部门 / 企业** 三维度展示 **生成成功率 / 成本 / 思考成熟度 / 抽卡浪费** 指标。

权限：需 `stats.read`（全局）或 `stats.department.read`（仅本部门）。

---

## 2. UI 单元清单

| 单元 | 内容 | 关键约束 |
|---|---|---|
| 全局筛选条 PeriodFilter | preset（昨日/最近 7/30/90 天/MTD/YTD）/ 自定义日期 / 部门多选 / 企业多选 / 同比开关 | 不作用于「前日/今日快照」（见 §6）|
| 8 KPI 卡 KpiCards（2×4）| 生成次数 / 成功率 / 总成本 / 真实产出（分钟）/ 活跃用户 / ¥/真实分钟 / 浪费率 / 平均抽卡 | 4 项含黄/红线阈值（见 §5）|
| 三趋势图 ThreeTrendCharts | 日完成/失败/取消 + 失败原因分布 + 成本（按 4 类+模型） + ¥/真实秒 | 可展开详情面板 |
| 前日/今日快照 SnapshotSection | 5 mini KPI + TOP10 用户卡片 + 成本构成 + 质量分布 + AI 摘要（LLM 异步生成 + Redis 缓存）| 独立日期参数（见 §6）|
| 三 Tab 明细表 DetailTables | 分人 / 分部门 / 分企业（15+ 列：生成/成功/失败/集群/有效秒/成本/思考分/浪费率等）| 分人 limit 200，部门/企业无 limit |
| 用户详情 Drawer UserDetailDrawer | 4 内嵌 Tab：元数据 / **AI 诊断（条件显示）** / 日趋势 / Cluster 列表 | Cluster limit 50；AI 诊断 Tab 仅当 `label='无脑抽卡型'` 显示 |

控件：列排序 / CSV 导出。

---

## 3. 接口清单

| 路由 | 方法 | 入参（关键）| 出参（顶层）|
|---|---|---|---|
| `/api/admin/generate-stats/kpi` | GET | preset / from-to / departments / companies / compare | period, current, previous?, delta? |
| `/api/admin/generate-stats/users` | GET | + sort_by + order + limit=200 | rows[] |
| `/api/admin/generate-stats/timeseries` | GET | 同上 | series[], cost_per_second_by_department[] |
| `/api/admin/generate-stats/snapshot` | GET | date（today / yesterday / YYYY-MM-DD）| summary, cost_breakdown, top_users[] |
| `/api/admin/generate-stats/quality-users-v2` | GET | preset / from-to / stat_date / departments / companies | rows[] |
| `/api/admin/generate-stats/quality-departments-v2` | GET | 同上 | rows[] |
| `/api/admin/quality/overview` | GET | period_days | totals{} |
| `/api/admin/quality/users/{userId}` | GET | period_days | user, daily[] |
| `/api/admin/quality/users/{userId}/clusters` | GET | limit=50 | clusters[] |
| `/api/admin/generate-stats/diagnoses/{userId}` | GET | period_type=daily | diagnosis{} |
| `/api/admin/generate-stats/llm-summary` | POST | body{...}, force_refresh? | summary, timestamp |
| `/api/admin/generate-stats/global-summary` | GET | period_type / date | summary{} |
| `/api/admin/generate-stats/export.csv` | GET | + group_by | CSV 流 |

---

## 4. 数据表清单

| 表 | 关键字段 | 用途 |
|---|---|---|
| `vg_task_clusters` | user_id, task_ids[], attempt_count, effective_seconds, total_cost_cny, effective_at, avg_edit_distance, cluster_score, centroid_embedding, **centroid_prompt** | 抽卡聚合（同用户对同画面多次抽卡聚成 1 个 cluster）|
| `vg_user_quality_daily` | user_id, stat_date(PK), total_attempts, clusters_converged_today, attempts_histogram, effective_seconds, total_cost_cny, thoughtfulness_score, waste_ratio, **label** | 用户日报；`label` 决定 Drawer AI 诊断 Tab 是否显示 |
| `vg_user_quality_assessment` | user_id, period_type, period_start(UNIQUE), assessment(JSONB), overall_score, model, cost_cny | LLM 评价（daily 16:00 / weekly 周一 03:00）|
| `vg_department_quality_daily`（VIEW）| company, department, stat_date, active_users, total_attempts, effective_seconds, cost_per_effective_second, avg_thoughtfulness_score | 部门聚合 |
| `vg_tasks` | user_id, task_type（video_gen / upscale / subtitle_erase）, status, created_at, effective_seconds | 原始任务（成本来自 core_pipeline.gen_events）|

---

## 5. ⚠️ 关键硬约束（PM 写新需求前必读）

新需求若涉及该模块，以下 hardcoded 值改动**必须在 PRD 第 8 章显式列出**，否则研发会按现值实现：

| 约束 | 当前值 | 来源 file:line |
|---|---|---|
| 成本黄/红线（¥/真实分钟）| 黄 ≥200 / 红 >300 | `frontend/components/admin/stats/kpi-cards.tsx:21-22` |
| 浪费率黄/红线 | 黄 >0.5 / 红 >0.7 | `kpi-cards.tsx:58-59` |
| 平均抽卡黄/红线 | 黄 >2 / 红 >5 | `kpi-cards.tsx:60-61` |
| 成功率警示 | <0.8 | `kpi-cards.tsx:81` |
| 用户列表 limit | 200 | `frontend/components/admin/stats/hooks.ts:103` |
| Cluster 列表 limit（admin 全局）| 50 | `hooks.ts:376` |
| 用户详情 Cluster limit（Drawer）| 50 | `frontend/components/admin/stats/user-detail-drawer.tsx:63` |
| 今日数据自动刷新 | 60 秒 | `hooks.ts:316` |
| AI 诊断 Tab 显示条件 | `label='无脑抽卡型'` | `user-detail-drawer.tsx:47` |
| 业务时区 | 上海 UTC+8 | `hooks.ts:176` |

---

## 6. 🔗 线上已有的设计模式（新需求要遵守，避免割裂一致性）

| 模式 | 现状 | 新需求设计要点 |
|---|---|---|
| **筛选作用范围分层** | 全局筛选条作用于「8 KPI + 三趋势图 + 三 Tab 明细表」3 块；**不**作用于「前日/今日快照」（独立日期参数）| 加新筛选条件要明确"作用到哪几块" |
| **Tab 条件显示** | Drawer 4 Tab 中 AI 诊断 Tab 是条件显示（仅 `label='无脑抽卡型'` 时出现）| 加新 Tab 时先想"是否也是条件显示"，避免用户体验跳跃 |
| **三维度共享指标定义** | 分人 / 分部门 / 分企业 3 个 Tab 共享同一组指标列定义 | 加新指标必须 3 个 Tab 一起加，不能只加 1 个 |
| **权限二级化** | stats.read（全局）/ stats.department.read（仅本部门）| 新功能必须指定走哪级权限，不能默认 read 一刀切 |
| **刷新策略** | 今日数据 60s 自动刷新；其他数据无自动刷新 | 新数据块默认无自动刷新，要有需 PRD 显式说明 |
| **TOP10 取数双源** | TopUsers 卡片：硬指标（生成次数/成本）来自 `vg_tasks`；软指标（浪费率/label）`LEFT JOIN vg_user_quality_daily` | 加新 TOP10 排序维度时要确认所属源表 |
| **LLM 评价异步**| AI 摘要 / 用户评价走 LLM 异步生成 + Redis 缓存（cron daily 16:00 / weekly 周一 03:00）| 加新 AI 文案不要走同步调用 |

---

## 7. 最近 3 个月活跃改动（PM 视角）

| commit / PR | PM 视角描述 |
|---|---|
| 4f33b7a | 权限二级化：stats.read / stats.department.read |
| 40b458d | 全局筛选跟随 + outbox 健康横幅（质量 pipeline 延迟告警）|
| 688b54d | 三趋势图 + 可展开详情面板 |
| 3983972 | 前日 / 今日快照独立于全局筛选 + 成本按 4 类拆分 |
| 2fc280a | 11 项口径微调（KPI / 浪费率阈值 / 思考分）|
| 3475948 | 5 项口径调整（4×2 KPI / TopUsers 4 排序 / 摘要联动）|
| 9f13162 | Cluster 详情独立页面（V2C-3）|
| 9f3a198 | 部门 Tab 横向柱图 + Drawer 4 内嵌 Tab + AI 诊断卡（V2C-2）|
| eb8eed3 | 9 KPI 卡 + LLM 重写 + 双 Tab + 个人分布柱图（V2C-1 首屏）|
| 085b377 | 初始化：完整 7 API + 7 组件 |

⚠️ **未上线改动**（在 docs/20260508/ batch 内）：Cluster 列表筛选升级 PRD 涉及 Drawer Cluster Tab 的 5 个筛选控件——尚未合入 main，本文不含。

---

## 8. 📍 反推可能不准的点

- `label` 字段枚举值：代码里只 grep 到 `'无脑抽卡型'`，其他枚举未确认（可能存在多个 label 值）
- 趋势图"按 4 类拆分"的 4 类具体名称：未深挖 commit 3983972
- LLM 评价 cron 时间（daily 16:00 / weekly 周一 03:00）：Explore agent 推断，未直接查 cron 定义
