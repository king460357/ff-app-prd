# FlareFlow App · 需求文档与产品线知识库

本仓库包含两类内容（推送目标：**https://github.com/king460357/ff-app-prd**）：

| 路径 | 用途 |
|------|------|
| `docs/{YYYYMMDD}/PRD/` | **当期 PRD**（真理源 `*_PRD.md`、html、assets） |
| `flareflow-app-snapshot/` | **历史需求知识库**（KNOWLEDGE_BASE、旧版 docx、全文检索索引） |

**AI 生成的新 PRD 只能落盘到本仓** `docs/...`，不得写入其它仓库。

## 结构

```
docs/
  {YYYYMMDD}/PRD/{需求名}/     ← 你写的需求文档
flareflow-app-snapshot/
  KNOWLEDGE_BASE.md            ← 产品线基线、画幅、与现行 PRD 冲突说明
  已上线功能/FF需求文档（App）/  ← 历史版本 docx（1.0～2.2.0）
  已上线功能/.../_EXTRACTED_INDEX.md
  tools/extract-archive-docx-index.ps1
```

## 使用本仓库写 PRD

1. 克隆 **[ff-app-prd-skill](https://github.com/king460357/ff-app-prd-skill)**（工作流 / Skill）与本仓。  
2. Cursor **多根工作区** 同时打开两仓，或将 skill 仓 `.claude` 复制到本仓根目录。  
3. 写新 PRD 前 AI 会检索：`KNOWLEDGE_BASE`、`_EXTRACTED_INDEX`、本仓已有 `docs/**/PRD/*.md`（见 skill 仓 `AGENTS.md`）。

## 重建 docx 抽取索引

```powershell
powershell -ExecutionPolicy Bypass -File "flareflow-app-snapshot/tools/extract-archive-docx-index.ps1"
```
