# 已确认决策

这里记录用户已经确认过的需求结论、方案选择、优先级、限制条件。

后续输出不得随意删除或推翻这里的内容。如需调整，必须说明原因（参见各「调整记录」子节）。

---

## 当前真理源速查（AI / PM 进入本文件后必先读）

> 本文件按时间顺序追加，旧记录保留作为历史。**判断"当前应该执行哪一版"以本表为准**，不要按时间顺序往下读到第一份方案就当成现行方案。

| 需求 | 当前真理源（最新版） | 当前版方案概览 | 已被取代的历史条目 | 当前 PRD 路径 |
|---|---|---|---|---|
| AutoFlow / 提示词版权风控规避 | `decision-making/AutoFlow/提示词版权风控规避/20260507_提示词版权风控规避.md`（2026-05-07 v2.2 事实核验修订）| 方案 D 增强版 — 静态映射 + 音乐强制改写 + 实时 tooltip + 资产 CN/OS 双状态显示（不做 TTL/续期 banner，Ark Asset Service 官方 10 个接口字段中均无 TTL/过期/续期字段）+ 跨模型适配 + AI 自动学习字典 + 人工 CRUD（编辑/软删/撤回）+ 变更记录 + 周快照回滚。错误码按官方 PascalCase 体系（`*SensitiveContentDetected.PolicyViolation` / `.PrivacyInformation` / `*RiskDetection`）。P0 / Minor 小 / **~6.9h** | 决策记录 #1（旧方案 A，~12-16h）| `prd/AutoFlow/提示词版权风控规避/00_PRD_主文档.md`（2026-05-07 v1.0，⚠️ 待按 v2.2 决策刷新）|
| AutoFlow / 通用参数校验框架（原图片视频参数预校验） | `decision-making/AutoFlow/通用参数校验框架/20260507_通用参数校验框架.md`（2026-05-07 v2 增强）| 范围 ③ 增强版 — 通用配置框架覆盖 10 个 API + 报白接口 19 项维度（尺寸 / 格式 / 色彩空间 / EXIF / 透明度 / 损坏 / 极端比例 / 资产名 / Group ID / TOS URL）+ 智能预校验 + 自动处理 + AI 失败诊断 + admin 配置 UI。P1 / Minor 大 / **~13.5h** | 决策记录 #2（旧方案 A，~16-24h）| _（PRD 待生成）_ |
| AutoFlow / Cluster 列表筛选升级（原 Cluster 日期过滤）| `decision-making/AutoFlow/Cluster列表筛选升级/20260507_Cluster列表筛选升级.md`（2026-05-07 v2 升级）| 方案 C — 抽屉 Cluster Tab 升级为完整筛选诊断面板（搜索 + 日期范围 + 排序 + 成功率三档筛 + 多重信号标 💰高成本/📏编辑距离异常/⚠️低成功率）+ URL 同步。P2 / Patch / **~2.5h** | 决策记录 #4（旧方案 A，~4-6h）| _（PRD 待生成）_ |

⚠️ **追加规则**：每次新增 / 更新决策时，必须同步更新本速查表。新增需求加新行；已有需求出现新调整记录时，把"当前真理源"列改为最新调整记录编号，旧编号挪到"已被取代的历史条目"列。

---

<!-- 决策记录从此处往下追加，每条按 ## 决策记录 #N 标题分节。
     已被取代的历史条目保留作历史参考，不删除，但顶部加废弃说明并指向最新版。 -->

## 决策记录 #1 — AutoFlow / 提示词版权风控规避（2026-05-06）

- **批次**：AutoFlow 2026-05-06 反馈批次（4 类决策中的 1）
- **优先级 / 版本类型 / 工时**：P0 / Patch / 12-16h
- **问题来源**：`docs/20260508/feedback/问题汇总表_20260506.xlsx` 第 5-9 行（卡迪 / 尼基音译明星拦截、音乐版权、水果 / 真人隐私一刀切）
- **选定方案**：A 快速版 — 敏感词中→英映射表 + 音乐版权强制 prompt 改写
- **核心改动**：
  - 新建 `prompt_safety_map.json`（中文音译明星 → 描述性英文）
  - 改造 `aigc_video_pipeline/agents/workers/visual_director.py:_sanitize_prompt`（加映射替换 + 音乐版权强制 append `instrumental only, no vocals`）
  - 前端 InputBar 加实时 tooltip 提示 + 新增 `prompt_safety_audit_log` 表
- **不做**：不改"破限模式"机制本身、不改资产报白底层逻辑、不上 prompt 二次 LLM 审核
- **验收红线**：版权类失败率从基线下降 ≥ 50%；映射表语境误判覆盖率 ≤ 5%
- **明细**：`docs/decision-making/AutoFlow/_汇总/20260506_需求决策汇总.md` 第 1 节

---

## 决策记录 #2 — AutoFlow / 图片视频参数预校验（2026-05-06）

- **批次**：AutoFlow 2026-05-06 反馈批次（4 类决策中的 2）
- **优先级 / 版本类型 / 工时**：P1 / Minor / 16-24h
- **问题来源**：`问题汇总表_20260506.xlsx` 第 2-3 行（Seedance 报白宽度 < 300px 或 > 6000px 失败、改视频像素过高）
- **选定方案**：B 完整版 — 前端尺寸预校验 + 后端 Pillow 自动 resize 兜底
- **核心改动**：
  - 前端 `frontend/lib/generate/upload-shared.ts` 加 width/height 校验（Seedance：300-6000px；改写视频 ≤ 4096px）
  - 后端新增 `aigc_video_pipeline/shared/asset_normalizer.py`（Pillow 等比缩放，原图保留，DB 双字段记录）
  - 收紧 `seedance.py` 错误码翻译（拆开过宽的 `invalid.*image` 模式）+ 前端文案精细化
- **不做**：不引入图像质量增强（不 upscale）、不在客户端跑 Pillow、不抽全局 ProviderConstraint registry
- **验收红线**：自动 resize 后报白成功率 ≥ 95%；竖图不被误识别变形
- **明细**：`docs/decision-making/AutoFlow/_汇总/20260506_需求决策汇总.md` 第 2 节

---

## 决策记录 #4 — AutoFlow / Cluster 列表日期过滤（2026-05-06）

- **批次**：AutoFlow 2026-05-06 反馈批次（4 类决策中的 4）
- **优先级 / 版本类型 / 工时**：P2 / Patch / 4-6h
- **问题来源**：`问题汇总表_20260506.xlsx` 第 11 行（后台人员明细 cluster 列表无日期、无日期过滤）
- **autoflow 现状**：表 `vg_task_clusters` 已有 effective_at / first_task_at / last_task_at 三字段，**无需补 DDL**；个人榜 / 部门榜已有 period_days，cluster 列表是漏网
- **选定方案**：A 快速版 — API 加日期参数 + 前端 DateRangePicker
- **核心改动**：
  - 后端 `cmd_user_clusters` 增 `effective_at_from / effective_at_to` 参数
  - 前端 `user-detail-drawer.tsx` Clusters Tab 顶部加 DateRangePicker（默认 30 天）+ 表头新增"生效日期"列 + URL query 同步
- **不做**：不改 DDL、不抽全局 `<DateRangeFilter>` 组件、不动其他已稳定的列表（个人榜 / 部门榜）
- **验收红线**：切换日期 < 500ms；未来日期 / from > to 不崩；Drawer 小屏不错乱
- **明细**：`docs/decision-making/AutoFlow/_汇总/20260506_需求决策汇总.md` 第 4 节

---
