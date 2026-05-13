---
模块: /review/art-assets — 艺术素材审核（P01-P05 多阶段）
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

`/review/art-assets` — 艺术素材审核主页，**6 个标签页**（脚本 / 导演 / 风格 / 角色 / 场景 / 道具），SSE 事件驱动 + HTTP 轮询双模式。

权限：
- `canSignOff`（lead_director / admin / hub）→ 才能做 P05 决议（approved / returned / partial_approved）
- reviewer 角色 → 可看不可决

---

## 2. UI 单元清单

| 单元 | 用途 |
|---|---|
| ArtHeader | 7 阶段 stepper（P01-P05 + 两个下游）+ 通知偏好；P05 通过前后 3 步 disabled + Lock 图标 |
| ArtNavSidebar | 6 section 导航（固定宽 192px）|
| ArtWorkspace | 主网格（CardState 状态机）|
| AssetCard | 单卡片（skeleton → pending → success → error 7 种状态）|
| AssetEditDialog | 追加候选编辑弹框 |
| Vr360Viewer | 360° 全景（dynamic import + ssr:false）|
| BatchReviewTab | QC 批次一致性检查（critical 阻断 approve）|
| ArtDecisionBar | 最终决议按钮（approved / returned / partial_approved）|
| FeedbackChatPanel | 4 层 scope 反馈（project / section / entity / asset）|

---

## 3. 接口清单

| 路由 | 方法 | 入参 | 出参顶层 |
|---|---|---|---|
| `/api/orchestrator/art-assets-review` | GET | project_id, mode?, task_id? | { project_id, p01, p02, p03, p04, p04a, partial_entities, gate_status, cost_estimate, whitelist_by_ref } |
| `/api/orchestrator/p04-regen` | POST | { project_id, asset_ids[], cascade?, reason? } | { success, idempotency_key, affected_assets } |
| `/api/orchestrator/p04-edit-regen` | POST | { project_id, asset_id, prompt, source_image_ref, model_override? } | { success, idempotency_key, candidate_index } |
| `/api/orchestrator/p05-select-candidate` | POST | { project_id, asset_id, selected_candidate_index } | { success, idempotency_key } |
| `/api/orchestrator/p05-status` | GET | project_id | { gate_status, regen_progress, can_approve } |
| `/api/orchestrator/p05-decision` | POST | { project_id, decision, feedback?, approved_entities?, reviewer_id? } | { success, idempotency_key } |
| `/api/projects/{id}/sign-off` | POST | { scope_decisions?, episode_assignments? } | { success, workflow_signal_id } |

> **所有 POST 支持幂等性**：`X-Idempotency-Key` header

---

## 4. 数据表清单

| 表 | 关键字段 | 用途 |
|---|---|---|
| `core_pipeline.gate_review_tasks` | project_id, gate_node_id='P05', status, approved_entities[], returned_entities[], decision, feedback | P05 gate 决议历史 + 部分通过实体 |
| `core_pipeline.gate_regen_jobs` | project_id, gate_task_id FK, asset_ids[], cascade, affected_assets[], status, result_json | P04 单资产 / 级联重生任务追踪 |
| `gen_events` | project_id, event_type, content | 审核反馈联动 |
| `vg_tasks` | project_id, task_id, status | 异步任务状态驱动 partial_entities 卡片占位 |

---

## 5. ⚠️ 关键硬约束（PM 写新需求前必读）

| 约束 | 当前值 | 来源 file:line |
|---|---|---|
| 道具卡每行数 | 3 | `art-workspace.tsx:148` PROPS_PER_ROW |
| 风格库卡每行数 | 4 | `art-workspace.tsx:149` STYLEREFS_PER_ROW |
| TOS 签名 URL 有效期 | 5.5 天 | `art-workspace.tsx:1289` TOS_SIGNED_URL_REFRESH_MS |
| TOS 刷新预热窗口 | 60 秒 | `art-workspace.tsx:1290` TOS_SIGNED_URL_VISIBILITY_GRACE_MS |
| P05 regen fanout 模式 | "fanout" | `p04-regen/route.ts:42` dispatch_mode |
| 决议有效值 | ["approved", "returned", "partial_approved"] | `p05-decision/route.ts:19` VALID_DECISIONS |
| P05 gate_node_id | "P05"（硬编码）| `p05-decision/route.ts:64` |
| QC 批次一致性阻断 | severity=critical 时 disable approve | `batch-review-tab.tsx` manifest.qc_summary.batch_consistency |
| 决议权限兜底 | canSignOff（lead_director / admin / hub）| `p05-decision/route.ts:60` |

---

## 6. 🔗 线上已有的设计模式（新需求要遵守）

| 模式 | 现状 | 新需求设计要点 |
|---|---|---|
| **分阶段审核 + 权限门控** | 7 阶段 stepper；canSignOff 前端隐藏 + 后端 requireProjectPermission 双网关 | 加新阶段必须前后端同名权限 |
| **Cascade 级联重生** | 选择候选 → 检测 cascade_required → 弹对话 → 列受影响资产 → 用户确认 reason → 单次 SIGNAL_REGEN_REQUEST fanout 派发 | 加新重生类型走相同对话链 |
| **Partial Entities 骨架并发** | P01 完成立返 skeleton；P02/P03 Promise.allSettled 并发填充；P04 单卡异步 patch | 加新阶段用相同骨架模式，避免白屏 |
| **VR360 dynamic import + 降级** | next/dynamic ssr:false；离开 tab 自动 viewer.destroy 释放 WebGL；加载超时/WebGL 不可用 → 降级 2D 图 | 加重 WebGL 组件用相同模式 |
| **TOS 签名 URL 预热调度** | 5.5 天周期刷新 + 60s 预热窗口主动重签 | 加新 TOS 资源用相同调度 |
| **QC 阻断逻辑解耦** | BatchReviewTab 通过 onCriticalDetected 通知父组件，父组件 disable 按钮 | 加新阻断条件用相同回调模式，不要在子组件改父状态 |
| **幂等性 Signal** | 所有 POST 支持 X-Idempotency-Key；Temporal Signal 消费端去重 | 加新 mutation 接口必须支持 idempotency-key |
| **飞书通知偏好** | P01-P05 五个检查点自动推送；用户可关闭 | 加新审核检查点接入相同推送 |

---

## 7. 最近 3 个月活跃改动（PM 视角）

| commit / PR | PM 视角描述 |
|---|---|
| #623 | 根概念重生跨变体级联（衣装 / 时间变体自动重做）|
| #610 | art-assets 审核页 UX 综合升级（卡片摘要文案 + CostumeCard 双布局 + 场景变体 sub-tab + hover 浮卡 + TOS 自动签名缩略图）|
| #601 | SSE partial_entities 更新时保留卡片状态（防闪烁）|
| #597 | P04 任务并行完成时实时刷新 TOS URL + fanout regen 进度联动 |
| #568 | p04-regen 改走 Temporal Signal（SIGNAL_REGEN_REQUEST），支持 dispatch_mode="fanout" |
| #567 | 卡片实时展示 QC 评分 0-5 星 + critical 红标阻断决议 |
| #519 | 集成飞书审核人通知（P01-P05 五检查点）|
| #562 | VR360 WebGL 不可用时降级 2D 图 |
| #561 | P04 VR360 全景渲染；regen 时保留旧候选快照对比 |
| #547 | P04 staging UAT 错误案例 / 权限校验 / 级联文案 |

---

## 8. 📍 反推可能不准的点

- "7 阶段 stepper" 具体步骤名（除 P01-P05 外两个下游叫什么）—— 未深挖 art-header.tsx
- BatchConsistency 三档（critical / warning / info）的具体判定逻辑 —— 仅看 severity 字段，未深挖判定算法
- AssetCard 7 种 CardState 的全集枚举 —— 只确认存在状态机，未列全
