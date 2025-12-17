# Repo Hygiene Baseline for PowerShell Formatting, Tests, Docs, and Static Analysis

> Issue: #1 (<https://github.com/joelvaneenwyk/hyper-v-automation/issues/1>)

## Description

## Problem

This repo has PowerShell scripts/modules but lacks the standard “quality rails” that modern PowerShell codebases use:
- Formatting is inconsistent and manual
- No unit test harness or CI gating
- Documentation isn’t generated/published automatically
- No static analysis/linting to catch common bugs/smells early

## Goals

- Make formatting deterministic and CI-enforced
- Add unit tests that run on every PR/push
- Generate readable docs and publish automatically to GitHub Pages
- Add static analysis to catch common issues before runtime

## Proposed Implementation

### 1) Auto-Formatting

Add repo-pinned formatting + make it run locally + in CI.

Deliverables
- `.editorconfig` (baseline whitespace/indent rules)
- `PSScriptAnalyzerSettings.psd1` (format + analysis config)
- `tools/format.ps1` (formats all `*.ps1/*.psm1/*.psd1` using PSScriptAnalyzer `Invoke-Formatter`)
- Optional
  - `.vscode/settings.json` to point the VS Code PowerShell extension at `PSScriptAnalyzerSettings.psd1`
  - `pre-commit` hook (or a simple `git hook`) to auto-run formatting before commits

Acceptance Criteria
- CI fails if `git diff` shows formatting changes after running `tools/format.ps1`
- Running `tools/format.ps1` locally produces zero diff after the first run

### 2) Unit Tests

Introduce Pester tests and CI execution.

Deliverables
- `tests/` folder with `*.Tests.ps1`
- `tools/test.ps1` that runs `Invoke-Pester` in CI-friendly mode
- `.github/workflows/ci.yml` runs tests on PRs and pushes to main
- Optional
  - coverage reporting + artifacts

Acceptance Criteria
- CI runs Pester on every PR and fails on test failures
- “Hello world” test exists to prove the harness works

### 3) Docs That Auto-Publish To GitHub Pages

Use comment-based help + platyPS to generate reference docs, then build a docs site (MkDocs is fine) and deploy via GitHub Actions Pages.

Deliverables
- Ensure all public functions have comment-based help
- platyPS usage
  - `docs/reference/` markdown generated/maintained via platyPS (or committed output)
- MkDocs site
  - `mkdocs.yml`
  - `docs/index.md`
  - optional `docs/reference/` included in nav
- GitHub Pages workflow (official actions approach)
  - `.github/workflows/pages.yml` builds site to `site/`
  - uploads via `actions/upload-pages-artifact`
  - deploys via `actions/deploy-pages`
- Repo Settings step (one-time)
  - Settings → Pages → Build and deployment source set to “GitHub Actions”

Acceptance Criteria
- On merge to `main`, docs deploy automatically and the Pages site renders without manual steps
- Docs build is reproducible in CI (no “works on my machine”)

### 4) Static Analysis

Run PSScriptAnalyzer as a CI gate with repo-pinned settings.

Deliverables
- `tools/lint.ps1` runs:
  - `Invoke-ScriptAnalyzer -Recurse -Settings ./PSScriptAnalyzerSettings.psd1`
- CI job step that fails on analyzer violations
- Optional (nice-to-have)
  - PSRule if we want additional repo-level checks (structure/policy/style patterns)

Acceptance Criteria
- CI fails on any PSScriptAnalyzer errors (and optionally warnings, depending on strictness)
- Analyzer config is checked into the repo and is the same for everyone

## File/Folder Plan

- `.editorconfig`
- `PSScriptAnalyzerSettings.psd1`
- `tools/format.ps1`
- `tools/lint.ps1`
- `tools/test.ps1`
- `tools/docs.ps1`
- `tests/*.Tests.ps1`
- `docs/` + `mkdocs.yml`
- `.github/workflows/ci.yml`
- `.github/workflows/pages.yml`

## Reference Repos To Use As Templates

PowerShell module/project scaffolding with tests/analysis/docs patterns
- https://github.com/gaelcolas/Sampler
- https://github.com/devblackops/Stucco
- https://github.com/deadlydog/PowerShell.ScriptModuleRepositoryTemplate
- https://github.com/ekkohdev/powershell-module-template

DSC “best practices” template (often the most opinionated/complete pipelines)
- https://github.com/PowerShell/DscResource.Template
- https://github.com/dsccommunity/DscResource.Test
- https://github.com/PowerShell/DscResource.Tests

Core tools we’re standardizing around
- https://github.com/PowerShell/PSScriptAnalyzer
- https://github.com/PowerShell/platyPS

GitHub Pages deployment (official actions)
- https://github.com/actions/upload-pages-artifact
- https://github.com/actions/deploy-pages

## Notes / Decisions

- Decide strictness level for analyzer warnings (warn vs fail)
- Decide whether formatting should be “auto-fix in CI” (usually no) vs “CI fails and dev fixes locally” (usually yes)
- Decide docs toolchain (MkDocs vs DocFX). MkDocs tends to be simpler + looks good fast.

