---
模块: /review/{visual,audiovisual,final} — 多阶段审核（E14/E16/E18）
最后验证日期: 2026-05-10
最后验证 commit: 7b70f34（autoflow main 分支）
反推方法: 代码扫描（前端 + 后端契约 + migrations + git log），未读 PRD
---

> 📌 **本文档是从 autoflow 代码反推的"现状速查"**——
> 只写代码 100% 反推可信的事实 + 代码可见的设计模式。
> 不写业务 why / 用户场景——那是 PRD 的活。
> 写新需求前重新 pull autoflow + 检查最后验证日期是否过期 4 周+。
>
> ⚠️ 本文是 3 个阶段审核（视觉 E14 / 视听 E16 / 成片 E18）的合并 snapshot。
> 与 `/review/art-assets`（艺术素材审核 P01-P05）是不同产品线，见 `art-review.md`。

---

## 1. 模块定位

3 个串行审核阶段，每个阶段一个 Gate 节点：

| 阶段 | URL | Gate | 粒度 | 角色链 | 用途 |
|---|---|---|---|---|---|
| **视觉** | `/review/visual?project_id=X` | E14 | shot_group（场景组）| director（单步）| 分镜候选版选择 + 质检 |
| **视听** | `/review/audiovisual` | E16 | episode | director → hub（**二步串行**）| 配音 + 音效 + 背景音乐整合审核 |
| **成片** | `/review/final` | E18 | episode | director → hub → partner（**三步串行**）| 合成成片三阶段质检与交付 |

---

## 2. UI 单元清单（共用 vs 独有）

**3 阶段共用**（`/components/layout` + `/components/shared`）：
- `GlobalNavSidebar`（全局侧边栏）
- `IconSidebar`（集号选择器，visual / audiovisual 用）

**视觉独有**（`/components/shared`）：
- `TopBar`（项目 + 进度条）
- `ShotDetailPanel`（分镜候选详情）
- `VideoPreview`（视频播放器）
- `AltPanel`（替选方案）
- `TimelineStrip`（时间线）

**视听独有**（`/components/av`）：
- `AVHeader`（视听头部）
- `AudioPanel`（配音 / 音效库）
- `AVVideoPlayer`（剧集视频播放）
- `NLETimeline`（非线编时间轴）
- `PropertiesPanel`（音频参数调节）

**成片独有**（`/components/final`）：
- `FinalHeader`（成片头部）
- `FinalVideoPlayer`（成片播放）
- `EpisodeStrip`（集号条带）
- `RevisionPanel`（版本回退历史）
- `ReviewPanel`（审阅打点面板）
- `SplitDeliveryPanel`（分包交付）

---

## 3. 已实现功能（按阶段）

**视觉审核（E14 / Stage 2）**：
- 场景组批量查看 + 按组展开/折叠
- 候选版 Gacha 选择与应用
- 单镜头/全集通过 + 重新生成请求
- 进度条：场景组完成度

**视听整合（E16 / Stage 3 — 二步串行）**：
- 导演步（Step 1）：配音生成 / 音效替换 / 配乐反馈 / 粗剪导出
- 中台步（Step 2）：只读模式（isReadOnly = currentStep === 2）
- 步骤提交流：导演全部批准 → 进入中台 → 最终确认

**成片审核（E18 / Stage 4 — 三步串行）**：
- 三步门禁：中台 → 合作方 → 合作方
- 审阅打点：时间戳 + 分类 + 评论
- 通过/驳回决策（review_points 同步后端）
- 版本回退（切换历史版本）
- 分包交付（批次管理 + 独立导出）

---

## 4. 接口清单

| 路由 | 方法 | 用途 |
|---|---|---|
| `/api/orchestrator/review/tasks?limit=100` | GET | 列举审核任务 |
| `/api/orchestrator/review/tasks/{taskId}` | GET | 单任务详情 |
| `/api/orchestrator/review/tasks/{taskId}/approve` | POST | 批准 |
| `/api/orchestrator/review/tasks/{taskId}/return` | POST | 驳回（创建 return_ticket）|
| `/api/orchestrator/review/tasks/{taskId}/skip` | POST | 跳过（仅 Stage4 Step1）|
| `/api/orchestrator/review/tasks/{taskId}/update-payload` | POST | 更新 payload（多态 JSON）|
| `/api/orchestrator/review/tasks/{taskId}/regenerate` | POST | 重新生成请求 |
| `/api/orchestrator/review/stage2-summary?episode_id=X` | GET | Stage 2 聚合状态 |
| `/api/orchestrator/review/stage3-summary?episode_id=X` | GET | Stage 3 聚合状态 |
| `/api/orchestrator/review/stage4-summary?episode_id=X` | GET | Stage 4 三步进度（含 current_step_no）|
| `/api/orchestrator/visual-review?project_id=X&episode_id=Y` | GET | 视觉审核数据加载（clips / episodes / p01 / p02）|

前端 hook：`useReviewTasks({ stage, role, status, limit })` → `{ tasks[], loading, error, reload }`。

---

## 5. 数据表清单

| 表 | 关键字段 | 用途 |
|---|---|---|
| `core_pipeline.gate_review_tasks` | id, project_id, gate_node_id（E14/E16/E18）, status, payload_json, return_ticket_id | 审核任务存储 |
| `core_pipeline.gate_regen_jobs` | id, gate_task_id FK, asset_ids[], status, result_json | 单资产 / 级联重生 |
| `public.review_tasks`（旧）| id, payload, status, decision | 向后兼容层 + RLS 策略 |
| `core_pipeline.return_tickets` | id, review_task_id, stage_no, source_type, issue_type, comment, status | 驳回工单 |

**多租户 RLS**：所有表加 `tenant_id UUID NOT NULL`；`WHERE tenant_id = current_setting('app.tenant_id')`；管理员 bypass `current_setting('app.bypass_rls')='true'`。

---

## 6. ⚠️ 关键硬约束（PM 写新需求前必读）

| 约束 | 当前值 | 来源 file:line |
|---|---|---|
| **视觉单镜头粒度** | granularity = "shot_group" | `visual/page.tsx:25-26`，`visual-review/route.ts:72` |
| **视听二步串行** | Step 1 → 2，必须序列化（不能并行跳过）| `audiovisual/page.tsx:27-35`，`handleSubmitStep:57-81` |
| **成片三步非可选** | Stage 4 三个步骤全必需，可 skip 但不能倒退 | `final/page.tsx:301-325` stage4Progress.steps[] |
| **Stage 4 Step 2+ 只读** | 不当前步骤时 UI disabled（disabled={isReadOnly}）| `final/page.tsx:48`，`audiovisual/page.tsx:48` |
| **审阅打点必填**（Stage 4 驳回前）| 必须 addReviewPoint，否则 toast.error | `final/page.tsx:183-187` |
| **回调管道恢复** | approve/return 响应含 resume_hint 时自动触发 Temporal resume_pipeline | `reviews.py:23-37` |
| **Payload 多态** | updateReviewTaskPayload 可承载任意 JSON 键（lock / prompt / track settings / audio_adjustments）| `review.ts:242-310` |
| **角色硬编码** | reviewer_role IN (director, hub, partner) 写在 `orchestrator.ts:39` 和 `audiovisual/page.tsx:33-34` | 加新角色需改 type + gate_reviewer_config + RBAC |

---

## 7. 🔗 线上已有的设计模式（新需求要遵守）

| 模式 | 现状 | 新需求设计要点 |
|---|---|---|
| **阶段分层** | stage_no（1/2/3/4）+ review_step_no 唯一确定位置；每阶段 1 个 Gate 节点（E14/E16/E18）| 加新阶段加 stage_no + 新 Gate 节点 |
| **串行流控** | E14 单步；E16 二步（Step 1 完成 setCompletedSteps + setCurrentStep）；E18 三步（fetchStage4Summary 异步查 current_step_no）| 加多步阶段用相同 currentStep + completedSteps + 后端 current_step_no |
| **Payload 多态扩展** | 任意 {key: value} 序列化到 payload_json JSONB 列；前端 lock / select / prompt / track / audio_adjustments 都这样存 | 加新阶段只需新 RegenType + 新 handleXXX 函数，调 requestRegeneration(taskId, newType, params) |
| **UI 不复用基类** | VideoPreview / AVVideoPlayer / FinalVideoPlayer 各自独立；TimelineStrip / NLETimeline 数据结构不兼容 | 不要强行抽基类，但播放状态（currentTime / isPlaying / onSeek）可抽 usePlayback hook |
| **角色权限隐含约束** | 角色硬编码在 type 与组件里 | 加新角色必须同时改 type + 后端 gate_reviewer_config + RBAC 表 |
| **回调管道恢复** | resume_hint 触发 Temporal resume_pipeline | 加新 gate 用相同 hint 协议 |
| **多租户 RLS** | 所有审核表带 tenant_id + RLS 策略 | 加新表必须 tenant_id NOT NULL + RLS |

---

## 8. 最近 3 个月活跃改动（PM 视角）

| commit / PR | PM 视角描述 |
|---|---|
| #519 | Feishu 审核人通知（也作用本模块）|
| #397 | SafeImg guard（visual / audiovisual / final 全 3 页）|
| 577d4ed | /generate 模块 + 配音选角 + TOS 重试 |
| 0db56d0 | V3 管道 / MCP / 前端大改造（基础架构）|

> **结论**：最近 3 月重点在 P04 art-review；本模块（visual/av/final）的改动主要是 2 月下旬一次性 MVP 实现，之后基本稳定（除小 UX 抛光）。

---

## 9. 📍 反推可能不准的点

- 视听 / 成片各步骤的"批准条件"具体细则 —— 仅看到二/三步串行结构，未深挖每步的明确通过条件
- return_ticket 的 issue_type 完整枚举 —— 字段存在但未列全集
- 视觉审核 Gacha 的具体候选数 / 切换 UI —— 仅看到 handleApplyGacha 入口
- `current_step_no` 与 `stage4Progress.steps[]` 的同步机制（前后端如何保证一致）
