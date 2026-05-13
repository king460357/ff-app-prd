---
模块: /generate — 创作者端视频/图片生成主工作区
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

`/generate` — 创作者端视频/图片生成主工作区，2 Tab：**生成**（默认）+ **资产管理**（ARK 报白资产库）。

支持模型：Seedance 2.0（视频）/ GPT-Image-2（图片，OpenAI 兼容）/ HappyHorse（图片，v1.0）/ 视频超分（fal.ai SeedVR2）/ 字幕擦除。

布局：二栏（左 InputBar 420-520px + 右 VideoHistory 虚拟化滚动列表）。

---

## 2. UI 单元清单

| 单元 | 用途 | 关键字段 |
|---|---|---|
| InputBar（左栏）| Lexical 富文本输入 + 资产选择 + 控件面板 | prompt / assets[] / modelId / ratio / resolution |
| MentionEditor | @资产触发选择器；displayName 跟随资产更新 | @mention chips |
| AssetPickerModal | 库资产/本地上传双源选择 | 库资产 ARK 枚举 + 上传实时预览 |
| UploadProgressBar | 上传进度环 + 错误状态 | uploadProgress (0-1) / uploadError |
| GenerationFilters | 时间 + 状态下拉筛选（仅"生成"Tab）| 三态：archived / active / all |
| VideoHistory | 虚拟化任务列表（react-virtuoso）| 任务卡片 / 缩略图 / 操作菜单 |
| VideoCard | 完成/失败任务卡（按 task_type 分化展示）| video_gen / image_gen / video_upscale / video_subtitle_erase |
| VersionCardRail | 同源任务多版本（HD 变体 + 字幕擦除变体）| hd_variant / erase_variant 嵌入父卡 |
| 资产管理 Tab | ARK 资产库列表 + 分类管理（character/scene/prop）| vg_assets 全集 |

---

## 3. 接口清单

| 路由 | 方法 | 入参 | 出参顶层 |
|---|---|---|---|
| `/api/generate/tasks` | GET | cursor / limit / status / archived | { tasks[], queue, hasMore } |
| `/api/generate/tasks` | POST | { prompt, mode, params, content[], model_id, ... } | { id, status, created_at, ... }（enqueue Redis）|
| `/api/generate/tasks/stream` | GET (SSE) | — | event: task.updated / asset.updated |
| `/api/generate/tasks/[id]/download` | GET | — | 重定向到签名 TOS URL |
| `/api/tasks/[id]/actions` | POST | { action: cancel\|retry\|archive\|... } | 操作结果 |
| `/api/generate/upload/presign` | POST | { files: [{ filename, contentType, size }] } | { uploads: [{ key, url }] } |
| `/api/generate/upload` | POST | multipart | { results }（legacy 代理上传）|
| `/api/generate/assets/presign` | POST | { files[], category: character\|scene\|prop } | { uploads } |
| `/api/generate/assets/register` | POST | { batch: [{ key, filename, category, displayName }] } | { results: [{ vgAssetId, jobId, jobIds?: {cn,os}, status }] } |
| `/api/generate/assets/status` | GET | jobId[] | 各 job 的 whitelist 进度 |
| `/api/generate/feature-flags` | GET | — | { UPLOAD_DIRECT_ENABLED, ... } |

---

## 4. 数据表清单

| 表 | 关键字段 | 用途 |
|---|---|---|
| `vg_tasks` | id, user_id, **task_type**（video_gen / image_gen / video_upscale / video_subtitle_erase）, status, prompt, content[], params, mode, model_id, video_url, tos_video_key, thumbnail_tos_key, error, **ark_phase**, archived_at, recovery_history, recovery_count, next_retry_at, **upscale_of_task_id**, **erase_of_task_id**, subtitle_detection_status | 生成任务（4 种类型多态）|
| `vg_assets` | id, user_id, tos_key, image_url, tags（CATEGORY）| 用户上传的报白资产库 |
| `whitelist_jobs` | id, vg_asset_id, status, tos_ref, **namespace**（'cn' / 'os'）| ARK CreateAsset 异步任务追踪 |
| `vg_users` | id, max_concurrent_tasks | 用户配额 + 并发限制 |
| `vg_audit_log` | id, user_id, action, target_type, params | 审计日志 |

---

## 5. ⚠️ 关键硬约束（PM 写新需求前必读）

| 约束 | 当前值 | 来源 file:line |
|---|---|---|
| **提示词长度（GPT-Image-2）** | ≤4000 字符 | `gpt-image-validators.ts:55` |
| **提示词长度（Seedance）** | 无服务端硬限 | — |
| **GPT-Image-2 参考图** | ≤16 张，单张 ≤25MB | `gpt-image-validators.ts:53-54` |
| **图片上传大小** | ≤30 MB | `upload-shared.ts:40` |
| **视频上传大小** | ≤50 MB | `upload-shared.ts:41` |
| **音频上传大小** | ≤15 MB | `upload-shared.ts:42` |
| **单批上传文件数** | ≤20 | `upload-shared.ts:61` |
| **直传并发** | 6（HTTP/1 socket pool 对齐）| `upload-engine.ts` PARALLEL_PUT_DEFAULT |
| **用户生成速率** | ≤10 req / 60s | `rate-limiter.ts:154` |
| **公网 IP 速率** | ≤30 req / 60s | `rate-limiter.ts:155` |
| **全局速率** | ≤1000 req / 60s | `rate-limiter.ts:156` |
| **队列统计缓存 TTL** | 30 秒 | `route.ts:67` |
| **签名 URL 有效期** | 7 天 | `upload-shared.ts:57` |
| **Presign 有效期** | 10 分钟 | `upload-shared.ts:51` |
| **资产名称（ARK）长度** | ≤64 字 | `input-bar.tsx:74` |
| **列表分页** | 默认 20，最大 50 | `route.ts:51-52` |
| **SSE 心跳间隔** | 30s（失效后降级 5s 轮询）| `use-tasks-stream.ts:100` |
| **SSE 重试** | 12 次后放弃 | `use-tasks-stream.ts:88` |
| **HD 变体 / 擦除变体** | 单源最多 1 个 HD + 1 个擦除 | `migrations/062, 064` |

---

## 6. 🔗 线上已有的设计模式（新需求要遵守）

| 模式 | 现状 | 新需求设计要点 |
|---|---|---|
| **任务多态（task_type 路由）**| video_gen / image_gen / video_upscale / video_subtitle_erase 共用 vg_tasks 表，UI 按 type 切换 video/image 展示、隐藏不适用按钮 | 加新任务类型加 task_type 枚举 + UI 适配，不另建表 |
| **异步任务三阶段** | ① 提交→Redis enqueue 立返 task id；② Worker 轮询 ARK（ark_phase: queued→running→succeeded）；③ Ark 回调触发 SSE 通知 | 加新任务流走同样三阶段，不要走同步等待 |
| **SSE + SWR 单一真相源** | SSE 单连接 / Redis pub/sub / 事件无数据（仅 id+status）/ 前端 SWR mutate 拉详情 / 失败降级 5s 轮询 | 加新实时推送类型加到 vg:tasks:user:&lt;id&gt; channel |
| **资产报白双 namespace** | cn=Seedance / os=破限，前端分别 mutate 两路缓存 | 加新 vendor 走相同 namespace 路由 |
| **直传上传 fail-fast** | 滑动窗口并发 6；单文件失败整批 throw（all-or-nothing 语义）| 加新上传流程要保留这种语义，避免半成品 |
| **进度聚合防脑裂** | perFileLoaded[] 累加 + emit | 加新进度展示用相同累加 |
| **HD/擦除变体嵌入父卡** | upscale_of_task_id / erase_of_task_id 外键 + UI 嵌入展示 | 加新变体类型用相同外键模式 |
| **租户隔离** | 所有任务 + 资产 + audit 都走 RLS 租户隔离（autoflow_token 解析）| 加新表必须有 user_id 或 tenant_id |
| **soft-delete** | archived_at 列实现存档；不真删 | 删除类操作走 archived_at，别 DELETE |

---

## 7. 最近 3 个月活跃改动（PM 视角）

| commit / PR | PM 视角描述 |
|---|---|
| #649 | /generate staging 流量分离（租户隔离加固）|
| #620 | 租户维度质量告警（outbox trigger）|
| #632 | P04 VR360 重生成按 asset 类型门控 |
| #610 | art-assets 审核页 UX 综合升级 |
| #577 | Temporal Workflow 工业化治理（恢复策略）|
| #218 | GPT-Image-2 端到端实现（kaopuyun OpenAI 兼容）|
| #219 | HappyHorse UX 对齐 Seedance（资产库 picker + asset:// 协议）|
| #217 | HappyHorse 补提交后 SWR revalidate |

---

## 8. 📍 反推可能不准的点

- "队列位置预测"逻辑（30s 缓存 + 全表 COUNT/AVG）是否在所有 vendor 都用——可能仅对 Seedance 有效
- 字幕擦除（video_subtitle_erase）的"拖拽涂鸦"UI 细节——只看到任务类型存在，未深挖前端交互
- ARK 报白的 cn/os 双 namespace 是否仅适用于"角色"类型（character），其他类型如 scene/prop 直 success
