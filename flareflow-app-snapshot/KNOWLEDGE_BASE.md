---
title: FlareFlow App 需求知识库
product: FlareFlow（短剧 App）
source_wedrive: https://drive.weixin.qq.com/s?k=AAsAkAdiAAsx0i30dN
source_note: 微信文档需登录；历史版本见 flareflow-app-snapshot/已上线功能
last_synced: 2026-05-13
maintainer: 产品负责人
---

# FlareFlow App 需求知识库

> **历史需求正文**：已落盘于 **`flareflow-app-snapshot/已上线功能/FF需求文档（App）/*.docx`**（FF 1.0 → FF-2.2.0 等 **30** 份）。**全文检索/AI 速读**优先打开同目录 **`_EXTRACTED_INDEX.md`**（从 docx 自动抽取纯文本预览；表格与版式以 docx 为准）。**约定**：`docs/` 仅存放按批次日期**新生成**的 PRD/决策等；FF 历史全量 docx 属**已上线能力沉淀**，放在 `flareflow-app-snapshot/已上线功能/`。  
> **冲突处理**：早期文档中的 **device_id / 游客 uid** 等规则可能与现行 **访客 VISITOR / 游客 GUEST** 合规方案不一致——写新需求时以 **当期批次 `docs/{YYYYMMDD}/PRD/.../*.md` 真理源** 为最高优先级，历史 docx 作背景参考。

---

## 0. 外部与本地真理源

| 类型 | 位置 |
|------|------|
| 历史需求（微信，需登录） | [drive.weixin.qq.com 需求文档](https://drive.weixin.qq.com/s?k=AAsAkAdiAAsx0i30dN) |
| **历史需求（本仓，可离线读）** | `flareflow-app-snapshot/已上线功能/FF需求文档（App）/*.docx` + **`_EXTRACTED_INDEX.md`** |
| UI（Figma） | FlareFlow-UI；Page 以当期 PRD 为准（如 **FF-V1.7.5**） |
| 现行 PRD 示例 | `docs/20260513/PRD/访客模式与游客身份/` |

---

## 1. 撰写基线（与仓库 skill / CLAUDE 对齐）

### 1.1 产品形态

- 原生 **iOS / Android** 竖屏 App；PRD 须含 **§4.0 App 规范 + 页面事实源**（Figma / `assets/screen-reference/`）。
- 底部 **4 Tab**：Discover → Reels → My List → Profile；逻辑画幅 **390×844 pt**。
- **原型 / mockup / ASCII / HTML 演示**：一律按 **移动端** 规范理解与绘制（竖屏优先、触控热区与安全区、单列主内容）；不以桌面 Web 为默认版式；横屏需求须单独写明。

### 1.2 产出物

- 批次目录 `docs/{YYYYMMDD}/...`；**md + html** 双产物；HTML 高保真机壳、禁用 ASCII 线框、`data-jump` 等见 `prd-writer-master` skill。

### 1.3 撰写原则

- 默认中文；可执行矩阵/状态机/验收；**研发免追问 PM**（见 skill）。

---

## 2. 历史版本文档索引（docx 文件名）

以下文件均在 **`flareflow-app-snapshot/已上线功能/FF需求文档（App）/`** 目录内（共 30 个）：

| # | 文档名 |
|---|--------|
| 1 | FF - 1.0 需求文档（App） (1).docx |
| 2 | FF - 1.1 需求文档（App） (1).docx |
| 3 | FF - 1.2 需求文档（App） (2).docx |
| 4 | FF - 1.2.10需求文档（App）.docx |
| 5 | FF - 1.2.11需求文档（App）.docx |
| 6 | FF - 1.2.3 需求文档（App） (1).docx |
| 7 | FF - 1.2.3 需求文档（App）.docx |
| 8 | FF - 1.2.6 需求文档（App） (1).docx |
| 9 | FF - 1.2.6 需求文档（App）.docx |
| 10 | FF - 1.2.8需求文档（App） (1).docx |
| 11 | FF - 1.2.8需求文档（App）.docx |
| 12 | FF - 1.3.0需求文档（App）.docx |
| 13 | FF - 1.3.5需求文档（App）.docx |
| 14 | FF - 1.5.0需求文档（App）.docx |
| 15 | FF - 1.5.5需求文档（App）.docx |
| 16 | FF - 1.6.0需求文档（App）.docx |
| 17 | FF - 1.6.5需求文档（App）.docx |
| 18 | FF - 1.7.0需求文档（App）-横屏&首页优化.docx |
| 19 | FF - 1.7.5需求文档（App）.docx |
| 20 | FF - 1.8.0需求文档（App）.docx |
| 21 | FF - 1.8.5需求文档（App）.docx |
| 22 | FF - 1.9.0需求文档（App）.docx |
| 23 | FF - 1.9.5需求文档（App）.docx |
| 24 | FF - 2.0.0需求文档（App）.docx |
| 25 | FF - 2.0.5需求文档(App) - 1.9.5遗留需求.docx |
| 26 | FF - 2.1.0需求文档(App) (1).docx |
| 27 | FF - 2.1.0需求文档(App) (2).docx |
| 28 | FF - 2.1.0需求文档(App).docx |
| 29 | FF - 2.1.5需求文档(App).docx |
| 30 | FF-2.2.0需求文档(App).docx |

**去重说明**：同一小版本存在多份带 `(1)` / `(2)` 的副本时，以**修改时间更新**或**与 Figma/发版号一致**的那份为准；必要时在决策表中单列「以哪份 docx 为事实源」。

---

## 3. 从 FF-1.0 抽取的体系梗概（⚠️  legacy，可能与现行 PRD 冲突）

以下内容来自 `_EXTRACTED_INDEX.md` 中 **FF-1.0** 篇预览，仅作**历史架构**速查；**不得**直接当作当前上线事实。

- **账号**：曾以 **device_id** 与 **uid**（含游客 uid）关系描述安装/卸载/三方绑定规则；用户 ID 序号自 10000000 起等。
- **登录**：Apple / Google / Meta；安卓与 iOS 登录方式差异描述。
- **登录引导弹窗**：付费成功、广告解锁后、首页到达等场景；频次「1 次/场景/天」等（现行以当期 PRD 为准）。
- **首页**：多样式模块（轮播、单排横图、瀑布流等）、Play Now、进沉浸页逻辑。
- **沉浸页**：播放、滑动、解锁、收藏、选集、分享、挽留弹窗等。
- **商业化**：广告、钱包、金币/bonus、SDK 列表（Fb/Google/ADMob 等）。
- **Figma**：1.0 文档内曾引用旧 Figma 链接（与现行 **FlareFlow-UI / FF-V1.7.5** 可能不同）。

---

## 4. 变更记录

| 日期 | 说明 |
|------|------|
| 2026-05-13 | 初始化骨架；登记微信链接 |
| 2026-05-13 | 用户归档 FF 历史共 30 份 docx；生成 `_EXTRACTED_INDEX.md`；本文件更新索引与 legacy 提示 |
| 2026-05-13 | **路径调整**：FF 历史 docx 迁至 `flareflow-app-snapshot/已上线功能/FF需求文档（App）/`（`docs/` 仅保留新批次产出） |
