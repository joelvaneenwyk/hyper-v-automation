# Refactor Repository Into Standard PowerShell Module Layout

> Issue: #5 (<https://github.com/joelvaneenwyk/hyper-v-automation/issues/5>)

## Overview

The repo currently ships loose scripts at the root. To align with common PowerShell module/library conventions, we should consolidate source into a `src/` module structure, add a module manifest, and update tooling/paths (lint, tests, docs) to work against the new layout. This improves discoverability, packaging, versioning, and makes CI tooling predictable.

## Goals

- Move all exported scripts/functions into a versioned module under `src/`
- Introduce a module manifest (`*.psd1`) and root module (`*.psm1`) for easy import
- Keep existing entry-point scripts working (thin wrappers that import the module)
- Update lint/test/docs/tooling paths to the new structure
- Prepare for publishing (gallery-ready layout, semantic versioning)

## Proposed Implementation

1) **Create module skeleton under `src/`**
- `src/HyperVAutomation.psm1` — imports public functions (or dot-sources files under `src/Public/`)
- `src/HyperVAutomation.psd1` — manifest with `RootModule`, `FunctionsToExport`, version, authors, license/project info
- `src/Public/` — exported functions (currently each script’s main function)
- `src/Private/` — internal helpers (shared utilities today scattered across scripts)

2) **Fold scripts into the module**
- Convert each top-level script into a public function file under `src/Public/`
- Preserve parameters and behavior; prefer one public function per file named like `New-VMFromWindowsImage.ps1`
- Keep `tools/` helper modules (Metadata/Virtio) under `src/Private/` if they are not direct entry points

3) **Retain CLI entry points for backward compatibility**
- Keep thin wrapper scripts at repo root (or `bin/`) that:
  - `Import-Module ./src/HyperVAutomation.psd1`
  - Invoke the corresponding public function
- Mark wrappers for future deprecation in README once the module is the primary consumption path

4) **Update tooling to target `src/`**
- `tools/lint.ps1` and `tools/format.ps1` recurse `src/` and wrappers
- `tools/test.ps1` loads module from `src/` before running Pester
- Docs generation (platyPS or existing flow) imports the module from `src/`

5) **Add packaging/publish scaffolding** (optional but recommended)
- `tools/package.ps1` to build a NuGet package from `src/`
- GitHub Actions job to publish on tagged releases (guarded)

6) **Documentation updates**
- README: add “Install/Import the module” section and note wrapper scripts are legacy
- Command summary: link to module functions, not just wrapper scripts

## Acceptance Criteria

- Source lives under `src/` with a valid `HyperVAutomation.psd1` manifest and `HyperVAutomation.psm1` root module
- Public functions exported via manifest and discoverable with `Get-Command -Module HyperVAutomation`
- Wrapper scripts continue to work and call into the module
- Lint/test/docs tooling runs against `src/` paths and succeeds
- README updated to describe the module-first usage pattern

## Suggested Task Breakdown

- Scaffold `src/` tree, manifest, root module
- Move/convert each script into `src/Public/` functions; move shared helpers into `src/Private/`
- Add/adjust wrapper scripts to load the module
- Point lint/format/test/docs tools at `src/`
- Update README and any docs that reference script paths
- (Optional) Add package/publish script and CI job for tagged releases

## Risks / Notes

- Wrapper maintenance: ensure parameter parity between wrappers and module functions
- Path churn: update any hard-coded relative paths in tooling/tests
- Signing/versioning: decide on semantic version and signing approach before publishing
