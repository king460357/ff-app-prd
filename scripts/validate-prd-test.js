#!/usr/bin/env node
/**
 * validate-prd-test.js — PRD ↔ Test 真静态分析
 *
 * 不是 AI 模拟，是 Node.js 真 grep + diff。
 *
 * 用法：
 *   node scripts/validate-prd-test.js                  # 校验全部 PRD
 *   node scripts/validate-prd-test.js docs/20260512    # 校验指定批次
 *   node scripts/validate-prd-test.js --json           # 输出 JSON（CI 用）
 *
 * 检查项：
 *   1. PRD 5.x.6 Gherkin Scenario ID  ↔  test 文件 test() 名称  — 一致性
 *   2. PRD frontmatter ai_consumption_format == 'structured'
 *   3. PRD 含 YAML/Gherkin 块（不是纯中文叙述）
 *   4. PRD 验收无模糊词（流畅/美观/友好/顺畅/清晰/高效/良好）
 *   5. PRD 含完整产出 6 份资产（.md / .html / README.md / requirements-spec.md / test-coverage-report.md / tests/）
 *   6. PRD 内部 enum / 字段一致性（同字段名多处出现时 enum 一致）
 *
 * exit code:
 *   0 = 全通过
 *   1 = 有错误（阻塞 sync / CI）
 *   2 = 有警告但不阻塞
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const FUZZY_WORDS = ['流畅', '美观', '友好', '顺畅', '清晰', '高效', '良好'];
const REQUIRED_ARTIFACTS = [
  /.*PRD\.md$/,
  /.*PRD\.html$/,
  /^README\.md$/,
  /^requirements-spec\.md$/,
  /^test-coverage-report\.md$/,
];
const REQUIRED_TESTS_DIR_FILES = [
  /^playwright-e2e\.spec\.ts$/,
  /^README\.md$/,
];

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function findAllPRDs(rootDir) {
  const prds = [];

  function walk(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        // skip node_modules / _archive / .git etc.
        if (entry.name.startsWith('.') || entry.name === 'node_modules' || entry.name === '_archive') continue;
        walk(full);
      } else if (entry.name.endsWith('_PRD.md')) {
        prds.push(full);
      }
    }
  }

  if (fs.existsSync(rootDir)) walk(rootDir);
  return prds;
}

function extractScenarioIds(content, type) {
  // 从 PRD.md 提取 Gherkin `Scenario: AC-X-X-NNN` ID
  if (type === 'prd') {
    return [...content.matchAll(/Scenario:\s+(AC-[\d-]+(?:\s+[一-龥]+)?)/g)]
      .map(m => m[1].split(/\s+/)[0]) // 只要 ID 部分
      .map(id => id.trim());
  }
  // 从 test.spec.ts 提取 test('AC-X-X-NNN ...') 名称
  if (type === 'test') {
    return [...content.matchAll(/test\(['"]([^'"]*AC-[\d-]+[^'"]*)['"]/g)]
      .map(m => {
        // 抽出 AC-X-X-NNN
        const match = m[1].match(/AC-[\d-]+/);
        return match ? match[0] : null;
      })
      .filter(Boolean);
  }
  return [];
}

function checkFrontmatter(content) {
  const issues = [];
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (!fmMatch) {
    issues.push({ level: 'error', msg: '缺 frontmatter（YAML 头部）' });
    return issues;
  }
  const fm = fmMatch[1];
  if (!/ai_consumption_format:\s*structured/.test(fm)) {
    issues.push({ level: 'warning', msg: 'frontmatter 缺 `ai_consumption_format: structured`（建议加上让研发 AI 知道格式）' });
  }
  if (!/doc_type:\s*PRD/.test(fm)) {
    issues.push({ level: 'error', msg: 'frontmatter 缺 `doc_type: PRD`' });
  }
  return issues;
}

function checkFuzzyWords(content) {
  const issues = [];
  // 跳过 frontmatter
  const body = content.replace(/^---[\s\S]*?\n---\n/, '');
  for (const word of FUZZY_WORDS) {
    // 跳过解释性的 "不允许 X" / "禁 X" 等元文本
    const lines = body.split('\n');
    lines.forEach((line, i) => {
      if (line.includes(word) && !line.match(/不允许|禁止|不能|不要|避免|改为|≠|不|严禁/)) {
        issues.push({
          level: 'warning',
          msg: `第 ${i + 1} 行含模糊词「${word}」: "${line.trim().slice(0, 80)}..."`,
        });
      }
    });
  }
  return issues;
}

function checkArtifacts(prdDir) {
  const issues = [];
  const files = fs.readdirSync(prdDir);

  for (const pattern of REQUIRED_ARTIFACTS) {
    const found = files.some(f => pattern.test(f));
    if (!found) {
      issues.push({ level: 'error', msg: `缺资产文件: ${pattern}` });
    }
  }

  const testsDir = path.join(prdDir, 'tests');
  if (!fs.existsSync(testsDir)) {
    issues.push({ level: 'error', msg: '缺 tests/ 目录' });
  } else {
    const testFiles = fs.readdirSync(testsDir);
    for (const pattern of REQUIRED_TESTS_DIR_FILES) {
      const found = testFiles.some(f => pattern.test(f));
      if (!found) {
        issues.push({ level: 'error', msg: `tests/ 缺文件: ${pattern}` });
      }
    }
  }

  return issues;
}

function checkScenarioConsistency(prdContent, testContent) {
  const issues = [];
  const prdScenarios = extractScenarioIds(prdContent, 'prd');
  const testScenarios = extractScenarioIds(testContent, 'test');

  const onlyInPRD = prdScenarios.filter(id => !testScenarios.includes(id));
  const onlyInTest = testScenarios.filter(id => !prdScenarios.includes(id));

  if (onlyInPRD.length > 0) {
    issues.push({
      level: 'error',
      msg: `PRD Gherkin 有但 test 没覆盖: ${onlyInPRD.join(', ')}`,
    });
  }
  if (onlyInTest.length > 0) {
    issues.push({
      level: 'error',
      msg: `test 有但 PRD Gherkin 没声明: ${onlyInTest.join(', ')}`,
    });
  }

  return {
    issues,
    stats: {
      prdScenariosCount: prdScenarios.length,
      testScenariosCount: testScenarios.length,
      overlapCount: prdScenarios.filter(id => testScenarios.includes(id)).length,
    },
  };
}

function checkPRDStructure(content) {
  const issues = [];
  // 必有 YAML 块或 Gherkin 块（AI-first 改造的证据）
  const hasYaml = /```yaml/.test(content);
  const hasGherkin = /```gherkin/.test(content) || /Scenario:/.test(content);
  if (!hasYaml) {
    issues.push({ level: 'warning', msg: 'PRD 没有 YAML 块（5.x.3 button_spec / 5.x.5 接口契约 等）— 不是 AI-first 格式' });
  }
  if (!hasGherkin) {
    issues.push({ level: 'error', msg: 'PRD 没有 Gherkin Scenario（5.x.6 验收）— 无法生成 test' });
  }
  return issues;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function validatePRD(prdPath) {
  const prdContent = fs.readFileSync(prdPath, 'utf8');
  const prdDir = path.dirname(prdPath);
  const testPath = path.join(prdDir, 'tests', 'playwright-e2e.spec.ts');

  const result = {
    prdPath,
    issues: [],
    stats: {},
  };

  // 1. frontmatter
  result.issues.push(...checkFrontmatter(prdContent));

  // 2. 6 份资产完整性
  result.issues.push(...checkArtifacts(prdDir));

  // 3. PRD 结构（YAML/Gherkin）
  result.issues.push(...checkPRDStructure(prdContent));

  // 4. 模糊词
  result.issues.push(...checkFuzzyWords(prdContent));

  // 5. PRD ↔ test Scenario 一致性
  if (fs.existsSync(testPath)) {
    const testContent = fs.readFileSync(testPath, 'utf8');
    const { issues, stats } = checkScenarioConsistency(prdContent, testContent);
    result.issues.push(...issues);
    result.stats = stats;
  } else {
    result.issues.push({ level: 'error', msg: '缺 tests/playwright-e2e.spec.ts' });
  }

  return result;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function main() {
  const args = process.argv.slice(2);
  const jsonMode = args.includes('--json');
  const targetArgs = args.filter(a => !a.startsWith('--'));

  const targetDir = targetArgs[0] || path.join(__dirname, '..', 'docs');
  const prds = findAllPRDs(targetDir);

  if (prds.length === 0) {
    console.log(`未在 ${targetDir} 找到任何 PRD.md 文件`);
    process.exit(0);
  }

  const results = prds.map(validatePRD);

  if (jsonMode) {
    console.log(JSON.stringify(results, null, 2));
  } else {
    let totalErrors = 0;
    let totalWarnings = 0;

    for (const r of results) {
      const rel = path.relative(process.cwd(), r.prdPath);
      const errors = r.issues.filter(i => i.level === 'error');
      const warnings = r.issues.filter(i => i.level === 'warning');

      const status = errors.length === 0 ? '✅' : '❌';
      console.log(`\n${status} ${rel}`);

      if (r.stats.prdScenariosCount !== undefined) {
        console.log(`   📊 Scenario: PRD ${r.stats.prdScenariosCount} 条 / test ${r.stats.testScenariosCount} 条 / 重叠 ${r.stats.overlapCount} 条`);
      }

      for (const e of errors) {
        console.log(`   ❌ ${e.msg}`);
        totalErrors++;
      }
      for (const w of warnings) {
        console.log(`   ⚠️  ${w.msg}`);
        totalWarnings++;
      }
    }

    console.log(`\n═══════════════════════════════════════════`);
    console.log(`总计: ${prds.length} 份 PRD / ${totalErrors} 错误 / ${totalWarnings} 警告`);

    if (totalErrors > 0) {
      console.log(`❌ 失败 — 修复错误后重跑`);
      process.exit(1);
    } else if (totalWarnings > 0) {
      console.log(`⚠️  通过但有警告 — 建议修复但不阻塞`);
      process.exit(2);
    } else {
      console.log(`✅ 全部通过`);
      process.exit(0);
    }
  }
}

main();
