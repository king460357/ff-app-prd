# FlareFlow App · 产品文档仓

本仓库 **仅** 维护 PRD、批次文档与产品线知识库。**不含** PM Skill / Agent / 工作流。

| 内容 | 仓库 |
|------|------|
| 本仓：PRD、知识库、历史 docx | [ff-app-prd](https://github.com/king460357/ff-app-prd)（当前） |
| Skill、决策门禁、五段工作流 | [ff-app-prd-skill](https://github.com/king460357/ff-app-prd-skill) |

用 Cursor 写 PRD 时，请同时打开 **ff-app-prd-skill**（或把其 `.claude` 复制到本仓根目录）。

## 默认语言

中文为主；技术字段、文件名可保留英文。

## PRD · Markdown 与 HTML

- **真理源**：`docs/{YYYYMMDD}/PRD/{需求名}/*_PRD.md`。  
- **未定稿**：不创建、不更新同名 `_PRD.html`。  
- **定稿后**：AI 提醒是否生成 HTML；**每次**生成 / 大改 HTML 前须你确认。  
- **改 `.md`**：先列拟改清单，经你确认并取得「同意修改」等许可后再落盘。  
- **写法与线框**：方法论在 **ff-app-prd-skill** 的 `prd-writer-master`；画幅与基线见本仓 `flareflow-app-snapshot/KNOWLEDGE_BASE.md` §1.1。

## 原型 / mockup · 移动端

需求对象为 **原生 iOS / Android 竖屏 App**：竖屏、触控热区、安全区；禁止默认桌面多栏布局。线框与弹窗逻辑同节、线框在逻辑之前（详见 skill 仓 `prd-writer-master`）。

## 目录

| 路径 | 内容 |
|------|------|
| `flareflow-app-snapshot/` | 知识库、历史 docx、抽取脚本 |
| `docs/{YYYYMMDD}/` | 按批次 PRD、README |

## 写新 PRD 时建议先读

1. `flareflow-app-snapshot/KNOWLEDGE_BASE.md`  
2. `flareflow-app-snapshot/已上线功能/FF需求文档（App）/_EXTRACTED_INDEX.md`  
3. 当期 `docs/.../PRD/.../*.md`  

**冲突优先级**：当期 PRD `.md` > `KNOWLEDGE_BASE.md` 已拍板 > 历史 docx。

## 重建 FF 抽取索引

```powershell
powershell -ExecutionPolicy Bypass -File "flareflow-app-snapshot/tools/extract-archive-docx-index.ps1"
```

## 交付物

PRD **只写入本仓库** 上述路径，勿写到仓外（除非你明确要求）。
