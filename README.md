# FlareFlow App · 产品文档仓

本仓库只维护 **FlareFlow 短剧 App** 相关：当期 PRD、产品线知识库、历史版本需求（docx）。

## 结构

```
flareflow-app-snapshot/  ← 知识库（KNOWLEDGE_BASE.md）、历史 docx、抽取脚本 tools/
docs/
  ├── PM_WORKFLOW_CURSOR.md  ← Cursor 五 Skill PM 工作流（总-分步骤）
  └── 20260513/          ← 示例批次：访客模式与游客身份 PRD（md + html + assets）
```

## 阅读顺序

1. `flareflow-app-snapshot/README.md`  
2. `flareflow-app-snapshot/KNOWLEDGE_BASE.md`  
3. `docs/20260513/PRD/访客模式与游客身份/` 内主 PRD `.md`  

## PM 工作流（Cursor · 五 Skill）

从反馈 → 决策 → **你确认** → PRD（**先 `.md` 定稿**）→ 你**再确认**后可选 HTML → 完整性校验的**步骤与产出物说明**：**[`docs/PM_WORKFLOW_CURSOR.md`](docs/PM_WORKFLOW_CURSOR.md)**。Skill 源码在 **`.claude/skills/`**。「先决策、确认后再写 PRD」及「**未定稿不生成 HTML**」见根目录 **`CLAUDE.md`**。

## 规则

见根目录 **`CLAUDE.md`**；产品 / 需求协作行为细则见 **`AGENTS.md`**。

## 团队成员 · 用同一套 Skill 写 PRD

本仓库 **即** [ff-app-prd](https://github.com/king460357/ff-app-prd) 工作区：克隆后直接用 Cursor / Claude Code 打开**仓库根目录**即可。

| 资产 | 路径 |
|------|------|
| 五段 PM Skill | `.claude/skills/open-questions-triage`、`Demand Solution Decision`、`spec-extractor`、`prd-writer-master`、`prd-test-validator` |
| 固定 Agent（可选） | `.claude/agents/demand-decision-agent.md`、`prd-writer-agent.md` |
| 工作流说明 | [`docs/PM_WORKFLOW_CURSOR.md`](docs/PM_WORKFLOW_CURSOR.md) |
| 已确认决策 / 优先队列 | [`docs/confirmed-decisions.md`](docs/confirmed-decisions.md)、[`docs/decision-priority-queue.md`](docs/decision-priority-queue.md) |
| 协作门禁 | `CLAUDE.md`、`AGENTS.md` |

**推荐用法（Cursor）**

1. 对话中 **@** 对应 `SKILL.md`，或说「按 Demand Solution Decision 做决策表」。  
2. **先决策、你确认后再写 PRD**（默认门禁，见 `CLAUDE.md`）。  
3. 写 PRD 时 @ `prd-writer-master/SKILL.md`，并按需 @ 同目录下 `interaction_detail_standard.md`、`ui_ascii_template.md` 等子文档。  
4. 定稿后可选 @ `prd-test-validator` 做 Gherkin 覆盖检查。

**可选 · superpowers-zh（工程向中文技能）**：编辑 `scripts/superpowers-zh.path` 指向本机 `superpowers-zh/skills` 目录后，在仓库根执行 `powershell -ExecutionPolicy Bypass -File scripts/link-superpowers-zh.ps1`（联结列表见 `.gitignore`）。

**示例 PRD 质量基准**：`docs/20260513/PRD/访客模式与游客身份/20260513_访客模式与游客身份_PRD.md`（真理源 `.md`）。
