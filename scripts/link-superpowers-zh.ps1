# Links each folder under superpowers-zh/skills into .claude/skills/ as directory junctions (Windows).
# Path resolution order: -SourceRoot > first line of scripts/superpowers-zh.path > error.
# Usage:
#   powershell -ExecutionPolicy Bypass -File "scripts\link-superpowers-zh.ps1"
#   powershell -ExecutionPolicy Bypass -File "scripts\link-superpowers-zh.ps1" -SourceRoot "D:\repos\superpowers-zh\skills"
param(
  [string] $SourceRoot = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$SkillsRoot = Join-Path $RepoRoot ".claude\skills"
$pathFile = Join-Path $PSScriptRoot "superpowers-zh.path"

if ([string]::IsNullOrWhiteSpace($SourceRoot) -and (Test-Path -LiteralPath $pathFile)) {
  $SourceRoot = (Get-Content -LiteralPath $pathFile -Encoding UTF8 | Select-Object -First 1).Trim()
}

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
  Write-Error "Set skills root: edit scripts/superpowers-zh.path (one line) or pass -SourceRoot."
}

if (-not (Test-Path -LiteralPath $SourceRoot)) {
  Write-Error "Source folder not found: $SourceRoot"
}

if (-not (Test-Path -LiteralPath $SkillsRoot)) {
  New-Item -ItemType Directory -Path $SkillsRoot | Out-Null
}

$reserved = @(
  "Demand Solution Decision",
  "open-questions-triage",
  "prd-writer-master",
  "prd-test-validator",
  "spec-extractor"
)

foreach ($dir in (Get-ChildItem -LiteralPath $SourceRoot -Directory)) {
  $name = $dir.Name
  $target = $dir.FullName
  $link = Join-Path $SkillsRoot $name

  if ($reserved -contains $name) {
    Write-Warning "Skip (reserved name): $name"
    continue
  }

  if (Test-Path -LiteralPath $link) {
    $item = Get-Item -LiteralPath $link -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
      Write-Host "Junction already exists, skip: $name"
    } else {
      Write-Warning "Path exists and is not a junction, skip: $link"
    }
    continue
  }

  New-Item -ItemType Junction -Path $link -Target $target | Out-Null
  Write-Host "Linked: $name"
}

Write-Host ""
Write-Host "Done. Example: .claude\skills\using-superpowers\SKILL.md"
