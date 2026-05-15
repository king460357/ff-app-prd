# flareflow-app-snapshot（FlareFlow App 沉淀区）

本目录集中存放 **FlareFlow 短剧 App** 的跨批次资产：产品线知识库、历史需求 docx 与抽取索引、维护脚本。

| 路径 | 说明 |
|------|------|
| `KNOWLEDGE_BASE.md` | 撰写基线、微信源链接、30 份历史 docx 索引、legacy 与现行 PRD 冲突说明 |
| `tools/extract-archive-docx-index.ps1` | 从 `已上线功能/FF需求文档（App）/*.docx` 重建 `_EXTRACTED_INDEX.md` |
| `已上线功能/FF需求文档（App）/` | 多版 `.docx` + `_EXTRACTED_INDEX.md`（纯文本抽取，便于检索） |

**新批次 PRD** 仍落在仓库根目录 **`docs/{YYYYMMDD}/...`**（见根目录 `CLAUDE.md`）。

与 **autoflow 后台** 无关；本仓仅 FF App 产品文档。
