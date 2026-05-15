# FlareFlow App · 产品文档仓

本仓库只维护 **FlareFlow 短剧 App** 的 **PRD 与知识库**（不含 PM Skill / 工作流）。

| 仓库 | 内容 |
|------|------|
| **本仓** [ff-app-prd](https://github.com/king460357/ff-app-prd) | `docs/{YYYYMMDD}/PRD/`、`_PRD.html`、`flareflow-app-snapshot/` |
| **[ff-app-prd-skill](https://github.com/king460357/ff-app-prd-skill)** | 五 Skill、双 Agent、`AGENTS.md`、决策门禁、[`PM_WORKFLOW_CURSOR.md`](https://github.com/king460357/ff-app-prd-skill/blob/main/docs/PM_WORKFLOW_CURSOR.md) |

## 结构

```
flareflow-app-snapshot/   ← KNOWLEDGE_BASE.md、历史 docx、抽取脚本
docs/
  └── 20260513/           ← 示例批次：访客模式与游客身份 PRD
  └── 20260514/           ← 示例批次：Android FCM 等
```

## 阅读顺序

1. `flareflow-app-snapshot/README.md`  
2. `flareflow-app-snapshot/KNOWLEDGE_BASE.md`  
3. `docs/20260513/PRD/访客模式与游客身份/` 内主 PRD `.md`  

## 规则

PRD 落盘、HTML、拟改确认见根目录 **`CLAUDE.md`**。  
**怎么写 PRD**（先决策、再确认、再撰写）见 **ff-app-prd-skill** 仓库。

## 用 AI 写 PRD

1. 克隆 **ff-app-prd-skill** 与 **本仓**，在 Cursor 中 **同时添加两个文件夹**。  
2. 在 skill 仓对话 @ Skill；PRD 写入 **本仓** `docs/...`。  
3. 示例质量基准：`docs/20260513/PRD/访客模式与游客身份/20260513_访客模式与游客身份_PRD.md`。
