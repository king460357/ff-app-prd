# HTML UI 渲染规范（PRD 派生展示版必读）

> 本文件给 prd-writer-agent 用——产出 HTML 派生展示版时**严格按本文件渲染**。
>
> **核心原则**：HTML 是给人类（评审 / 自审 / 跨团队展示）看的，必须**所见即所得**。markdown 端用 ASCII 草图开发 AI 易读，HTML 端必须用真实 dark theme + shadcn 密度的 HTML/CSS 渲染。
>
> **触发时机**：每次产出 PRD 双产物的 `.html` 派生展示版时。

---

## 1. 硬约束（违反即返工）

### 1.1 禁用 ASCII 线框图

HTML 中**任何 UI mockup 都不允许**用 `<pre><code>` 包裹 box-drawing 字符（`┌` `─` `┐` `│` `└` `┘` `├` `┤` `┬` `┴` `┼`）来渲染：

| 不允许 ❌ | 必须用 ✅ |
|---|---|
| `<pre><code>┌──┐│ Dialog 标题 │└──┘</code></pre>` | `<div class="dialog-mockup">` 真实 HTML/CSS 渲染 |
| ASCII 月历 `日 一 二 三 四 五 六` | `<div style="display:grid;grid-template-columns:repeat(7,1fr)">` 真实月历 grid |
| ASCII 单选 `◉ 全部 ○ 高` | `<span style="width:14px;height:14px;border:2px solid var(--primary);border-radius:50%;">` 真实 radio |
| ASCII 按钮 `[取消] [保存]` | `<span class="btn btn-outline">取消</span>` `<span class="btn btn-primary">保存</span>` |
| ASCII textarea `[___________]` | `<div class="dialog-field textarea placeholder">输入...</div>` |

**自检**：`grep -c '<pre><code>┌' file.html` 必须 = 0。

**例外**：以下内容**允许**用 `<pre><code>` 但 **不允许** box-drawing 字符：
- JSON 请求体 / Response
- SQL DDL
- 流水线伪代码 / shell 命令
- URL 示例

### 1.2 强制 dark theme + globals.css 色值

HTML `<style>` 段顶部必须含：

```css
:root {
  --bg: #111111;             /* 页面背景 */
  --card: #1F2937;           /* 卡片 / Dialog / Popover 背景 */
  --fg: #F9FAFB;             /* 主文字 */
  --muted-fg: #9CA3AF;       /* 次文字 */
  --border: #374151;         /* 边框 / 分隔线 */
  --primary: #3B82F6;        /* 主色 CTA / 链接 / 焦点环 */
  --score-green: #10B981;    /* 成功 / 已核验 / 高成功率 */
  --score-yellow: #F59E0B;   /* 警告 / 待核验 / 中成功率 */
  --score-red: #EF4444;      /* 危险 / 失败 / 低成功率 */
}
body { background: var(--bg); color: var(--fg); }
```

色值唯一事实源是 autoflow `frontend/app/globals.css:6-45` —— 任何 PRD 表格如与 globals.css 冲突，以 globals.css 为准。

---

## 2. Dialog / AlertDialog 标准 CSS 类（必有）

每份 PRD HTML 的 `<style>` 段都要含以下 Dialog 渲染基础类：

```css
/* ==== Dialog 实物 UI 渲染（替代 ASCII 线框图）==== */
.dialog-mockup { background: var(--card); border: 1px solid var(--border); border-radius: 8px; margin: 16px auto; max-width: 576px; overflow: hidden; }
.dialog-mockup.size-xs { max-width: 320px; }
.dialog-mockup.size-sm { max-width: 384px; }
.dialog-mockup.size-md { max-width: 448px; }
.dialog-mockup.size-lg { max-width: 512px; }
.dialog-mockup.size-xl { max-width: 576px; }
.dialog-mockup.size-2xl { max-width: 672px; }
.dialog-header { padding: 12px 16px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; font-weight: 500; font-size: 14px; color: var(--fg); }
.dialog-close { color: var(--muted-fg); cursor: pointer; font-size: 16px; line-height: 1; }
.dialog-body { padding: 16px; font-size: 13px; }
.dialog-row { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 12px; }
.dialog-row > label { width: 92px; color: var(--muted-fg); flex-shrink: 0; padding-top: 6px; font-size: 12px; }
.dialog-row .required { color: var(--score-red); margin-left: 2px; }
.dialog-field { flex: 1; padding: 6px 10px; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; color: var(--fg); font-size: 13px; min-height: 28px; display: flex; align-items: center; box-sizing: border-box; }
.dialog-field.textarea { min-height: 60px; align-items: flex-start; padding-top: 8px; }
.dialog-field.textarea.tall { min-height: 80px; }
.dialog-field.placeholder { color: #6B7280; }
.dialog-field.select { justify-content: space-between; }
.dialog-field.select::after { content: '▼'; color: var(--muted-fg); font-size: 10px; }
.dialog-readonly { background: rgba(31,41,55,0.5); border: 1px solid var(--border); border-radius: 4px; padding: 10px 12px; margin-bottom: 12px; font-size: 12px; color: var(--muted-fg); }
.dialog-readonly strong { color: var(--fg); font-size: 13px; display: block; margin-bottom: 6px; }
.dialog-switch { display: inline-flex; align-items: center; width: 34px; height: 18px; background: var(--primary); border-radius: 9px; position: relative; flex-shrink: 0; }
.dialog-switch::after { content: ''; position: absolute; right: 2px; top: 2px; width: 14px; height: 14px; background: #fff; border-radius: 50%; }
.dialog-switch.off { background: var(--border); }
.dialog-switch.off::after { left: 2px; right: auto; }
.dialog-footer { padding: 12px 16px; border-top: 1px solid var(--border); display: flex; justify-content: flex-end; gap: 8px; background: rgba(0,0,0,0.15); }
.dialog-alert-body { padding: 16px; font-size: 13px; line-height: 1.7; color: var(--fg); }
.dialog-alert-body .warn-icon { color: var(--score-yellow); margin-right: 4px; }
.dialog-alert-body code { background: rgba(245,158,11,0.08); padding: 1px 6px; border-radius: 3px; }
.dialog-hint { font-size: 11px; color: var(--muted-fg); margin-top: 4px; padding-left: 102px; }
.dialog-radio-group label { display: block; padding: 4px 0; font-size: 13px; color: var(--fg); }

/* 按钮（如 PRD 已有就跳过）*/
.btn { background: var(--bg); border: 1px solid var(--border); padding: 5px 12px; border-radius: 6px; font-size: 12px; color: var(--fg); display: inline-flex; align-items: center; gap: 4px; cursor: pointer; }
.btn-primary { background: var(--primary); color: #fff; border-color: var(--primary); }
.btn-destructive { background: var(--score-red); color: #fff; border-color: var(--score-red); }
.btn-outline { background: transparent; }
.btn-ghost { background: transparent; border: 0; color: var(--fg); padding: 4px 8px; }
```

---

## 3. Dialog 渲染常见模板

### 3.1 表单 Dialog（多字段）

```html
<div class="dialog-mockup size-xl">
  <div class="dialog-header">
    <span>添加 / 编辑风险词</span>
    <span class="dialog-close">×</span>
  </div>
  <div class="dialog-body">
    <div class="dialog-row">
      <label>风险词<span class="required">*</span></label>
      <div class="dialog-field placeholder">输入风险词（≤ 50 字符，表内唯一）</div>
    </div>
    <div class="dialog-row">
      <label>安全替代<span class="required">*</span></label>
      <div class="dialog-field textarea placeholder">输入安全替代（textarea 3 行，≤ 200 字符）</div>
    </div>
    <div class="dialog-row">
      <label>类别<span class="required">*</span></label>
      <div class="dialog-field select"><span>celebrity</span></div>
      <span style="font-size:11px;color:var(--muted-fg);white-space:nowrap;">6 项</span>
    </div>
    <div class="dialog-row">
      <label>启用</label>
      <span class="dialog-switch"></span>
      <span style="font-size:12px;color:var(--muted-fg);">已开启</span>
    </div>
  </div>
  <div class="dialog-footer">
    <span class="btn btn-outline">取消</span>
    <span class="btn btn-primary">保存</span>
  </div>
</div>
```

### 3.2 AlertDialog（二次确认）

```html
<div class="dialog-mockup size-xs">
  <div class="dialog-header">
    <span><span class="warn-icon">⚠️</span> 确定撤回 "{risk_word}" ?</span>
  </div>
  <div class="dialog-alert-body">
    此 AI 入库条目将从字典移除。<br>
    <span class="warn-icon">⚠️</span> 下次 cron 仍可能再次推荐<br>
    <span style="color:var(--muted-fg);font-size:12px;">（已同步到 review 队列防止重推）</span>
  </div>
  <div class="dialog-footer">
    <span class="btn btn-outline">取消</span>
    <span class="btn btn-destructive">撤回</span>
  </div>
</div>
```

### 3.3 只读区块 + 编辑区组合 Dialog

```html
<div class="dialog-mockup size-xl">
  <div class="dialog-header"><span>✏️ 改写后采纳：review#247</span><span class="dialog-close">×</span></div>
  <div class="dialog-body">
    <div class="dialog-readonly">
      <strong>📌 AI 原始推荐（只读，供参考）</strong>
      <div style="display:grid;grid-template-columns:90px 1fr;gap:4px 10px;">
        <span>risk_word</span><span style="color:var(--fg);">"小米"</span>
        <span>confidence</span><span style="color:var(--score-yellow);">75%</span>
      </div>
    </div>
    <div style="font-size:12px;color:var(--muted-fg);margin:10px 0;">↓ admin 改写区（可改）</div>
    <div class="dialog-row"><label>风险词<span class="required">*</span></label><div class="dialog-field">小米</div></div>
  </div>
  <div class="dialog-footer"><span class="btn btn-outline">取消</span><span class="btn btn-primary">✓ 确认采纳</span></div>
</div>
```

---

## 4. Popover 渲染常见模板

### 4.1 Calendar Popover（日期选择器）

```html
<div style="display:flex;align-items:flex-start;gap:24px;margin:16px 0;">
  <span class="btn btn-outline" style="white-space:nowrap;">📅 2026-04-30 → 05-06</span>
  <div style="color:var(--muted-fg);font-size:12px;padding-top:8px;">← 点击此按钮 ↓</div>
  <div style="background:var(--card);border:1px solid var(--border);border-radius:8px;padding:0;min-width:320px;box-shadow:0 4px 12px rgba(0,0,0,0.4);">
    <div style="padding:10px 14px;border-bottom:1px solid var(--border);font-size:13px;font-weight:500;display:flex;justify-content:space-between;">
      <span>选择日期范围</span><span style="color:var(--muted-fg);cursor:pointer;">×</span>
    </div>
    <div style="padding:10px 14px;font-size:12px;">
      <span class="btn btn-outline" style="font-size:11px;padding:2px 8px;">7 天</span>
      <span class="btn btn-outline" style="font-size:11px;padding:2px 8px;">30 天</span>
    </div>
    <div style="padding:12px 14px;">
      <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:4px;font-size:11px;text-align:center;color:var(--muted-fg);">
        <span>日</span><span>一</span><span>二</span><span>三</span><span>四</span><span>五</span><span>六</span>
      </div>
      <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:2px;font-size:12px;text-align:center;">
        <span style="padding:4px;background:var(--primary);color:#fff;border-radius:50%;">30</span>
        <span style="padding:4px;background:rgba(59,130,246,0.15);">1</span>
        <!-- 更多日期 -->
      </div>
    </div>
    <div style="padding:10px 14px;border-top:1px solid var(--border);display:flex;justify-content:flex-end;gap:8px;background:rgba(0,0,0,0.15);">
      <span class="btn btn-outline">取消</span><span class="btn btn-primary">应用</span>
    </div>
  </div>
</div>
```

### 4.2 Radio Select Popover（单选下拉）

```html
<div style="display:flex;align-items:flex-start;gap:24px;margin:16px 0;">
  <span class="btn btn-outline">全部 ▼</span>
  <div style="color:var(--muted-fg);font-size:12px;padding-top:8px;">← 点击此按钮 ↓</div>
  <div style="background:var(--card);border:1px solid var(--border);border-radius:6px;padding:6px;min-width:240px;box-shadow:0 4px 12px rgba(0,0,0,0.4);">
    <div style="padding:8px 10px;background:rgba(59,130,246,0.12);border-radius:4px;font-size:13px;display:flex;align-items:center;gap:8px;cursor:pointer;">
      <span style="width:14px;height:14px;border:2px solid var(--primary);border-radius:50%;display:inline-flex;align-items:center;justify-content:center;">
        <span style="width:6px;height:6px;background:var(--primary);border-radius:50%;"></span>
      </span>
      <span>全部</span>
    </div>
    <div style="padding:8px 10px;font-size:13px;display:flex;align-items:center;gap:8px;cursor:pointer;">
      <span style="width:14px;height:14px;border:2px solid var(--border);border-radius:50%;display:inline-block;"></span>
      <span>🟢 高成功率（≥ 80%）</span>
    </div>
  </div>
</div>
```

---

## 5. data-jump 跳转三件套（必有）

### 5.1 CSS（放在 `<style>` 段末尾）

```css
/* ==== data-jump 跳转：mockup 元素 → PRD 章节 ==== */
[data-jump] { cursor: pointer !important; position: relative; transition: outline 0.15s; }
[data-jump]:hover { outline: 1px dashed var(--primary); outline-offset: 2px; }
[data-jump]:hover::after {
  content: '→ ' attr(data-jump-label);
  position: absolute; bottom: calc(100% + 6px); left: 50%; transform: translateX(-50%);
  background: var(--primary); color: #fff; padding: 4px 10px; border-radius: 4px;
  font-size: 11px; white-space: nowrap; z-index: 1000;
  box-shadow: 0 2px 6px rgba(0,0,0,0.4); pointer-events: none;
}
.jump-highlight { animation: jump-flash 1.4s ease-out; }
@keyframes jump-flash {
  0% { background: rgba(59, 130, 246, 0.25); box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.4); }
  100% { background: transparent; box-shadow: 0 0 0 0 transparent; }
}
```

### 5.2 JS（放在 `<script>` 段 IIFE 内最前面）

```javascript
// ★ data-jump 跳转：UI mockup 元素点击 → 滚动到对应 PRD 章节 + 闪烁高亮
document.querySelectorAll('[data-jump]').forEach(el => {
  el.addEventListener('click', (e) => {
    e.stopPropagation();
    e.preventDefault();
    const targetId = el.dataset.jump;
    const target = document.getElementById(targetId);
    if (target) {
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      target.classList.add('jump-highlight');
      setTimeout(() => target.classList.remove('jump-highlight'), 1400);
    } else {
      // Fallback：无对应章节时显示 toast
      const toast = document.createElement('div');
      toast.style.cssText = 'position:fixed;bottom:20px;right:20px;background:var(--card);border:1px solid var(--score-yellow);padding:10px 16px;border-radius:6px;font-size:13px;color:var(--fg);z-index:9999;box-shadow:0 4px 12px rgba(0,0,0,0.4);';
      toast.textContent = '⚠️ ' + (el.dataset.jumpLabel || '该按钮暂无对应 PRD 章节描述');
      document.body.appendChild(toast);
      setTimeout(() => { toast.style.opacity = '0'; toast.style.transition = 'opacity 0.3s'; setTimeout(() => toast.remove(), 300); }, 2000);
    }
  });
});
```

### 5.3 HTML 属性（每个 mockup 元素）

```html
<!-- 表格行内按钮 -->
<span class="btn btn-ghost" data-jump="sec-5-3-3-c3" data-jump-label="见 5.3.3 控件 3：行内编辑按钮">编辑</span>

<!-- 顶部 toolbar 按钮 -->
<span class="btn btn-primary" data-jump="sec-5-3-3-c1" data-jump-label="见 5.3.3 控件 1：手动添加">+ 手动添加</span>

<!-- Popover 触发器 -->
<span class="btn" data-jump="sec-5-1-4-pop-1" data-jump-label="见 5.1.4 轻量弹层 1：日期范围选择器">📅 2026-04-30 → 05-06</span>

<!-- 无对应章节的演示按钮（fallback toast）-->
<span class="btn" data-jump="无章节" data-jump-label="演示态，PRD 未定义对应章节">演示按钮</span>
```

### 5.4 控件锚点 id 命名约定

PRD markdown 端的控件清单段必须用 `<a id="..."></a>` 或 HTML 元素 `id="..."` 标记锚点；HTML 端的控件清单 li / h4 自带 id：

| 锚点 id | 含义 |
|---|---|
| `sec-5-3` | 5.3 模块整体 |
| `sec-5-3-3` | 5.3.3 控件清单段 |
| `sec-5-3-3-c1` | 5.3.3 控件 1（[+ 手动添加]）|
| `sec-5-3-3-c2` | 5.3.3 控件 2 |
| `sec-5-3-4-dialog-1` | 5.3.4 Dialog 1 |
| `sec-5-3-4-dialog-2` | 5.3.4 Dialog 2 |
| `sec-5-1-4-pop-1` | 5.1.4 轻量弹层 1 |

---

## 6. 产出 HTML 时的自检清单

写完 HTML 后**逐项核查**：

- [ ] `grep -c '<pre><code>┌' file.html` = 0（无 ASCII Dialog 框）
- [ ] `grep -c '<pre><code>│' file.html` = 0（无 ASCII 边框字符）
- [ ] `grep -c '\.dialog-mockup' file.html` ≥ Dialog 总数（5.x.4 列出的所有 Dialog 都有真实渲染）
- [ ] `grep -c 'data-jump=' file.html` ≥ ASCII 草图中按钮数 + 表格操作列按钮数（每个 mockup 元素都有 data-jump）
- [ ] `grep 'querySelectorAll.*data-jump' file.html` 命中（确认 JS handler 存在）
- [ ] `grep '@keyframes jump-flash' file.html` 命中（确认动画 CSS 存在）
- [ ] `grep '\.jump-highlight' file.html` 命中（确认高亮类存在）
- [ ] 浏览器打开后，hover 任一 mockup 按钮显示蓝色 tooltip 「→ 见 5.x.y ...」
- [ ] 点击任一 mockup 按钮平滑滚动到对应章节 + 1.4s 蓝色闪烁高亮
- [ ] dark theme 三锁（globals.css :root + layout.tsx themeColor + Toaster dark）色值与 globals.css 一致
- [ ] 顶部含 `<div class="notice notice-info">` "怎么打开看" 段
- [ ] 同目录有 `README.md` 引导本地打开

任一项不达标 → 返工。
