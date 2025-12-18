# GitHub Copilot Custom Instructions

This file contains custom instructions for GitHub Copilot to improve code quality and maintain consistency across the repository.

## Code Formatting

**IMPORTANT: Always run the formatter before committing any changes.**

Before making any commits, you MUST run the PowerShell formatter to ensure all code follows the repository's formatting standards:

```powershell
./tools/format.ps1
```

To check if files need formatting without modifying them (useful in CI):

```powershell
./tools/format.ps1 -Check
```

The formatter uses PSScriptAnalyzer with settings defined in `PSScriptAnalyzerSettings.psd1` to ensure consistent code style across all PowerShell files (*.ps1, *.psm1, *.psd1).

## Testing

Before committing changes, run the test suite to ensure all tests pass:

```powershell
./tools/test.ps1
```

## Linting

Run PSScriptAnalyzer to check for code quality issues:

```powershell
./tools/lint.ps1
```

## Module Structure

This repository follows a standard PowerShell module layout:

- `src/HyperVAutomation/` - Main module directory
  - `HyperVAutomation.psd1` - Module manifest
  - `HyperVAutomation.psm1` - Root module file
  - `Public/` - Exported functions (17 functions)
  - `Private/` - Internal helper functions

## Workflow

1. Make code changes
2. **Run formatter**: `./tools/format.ps1` (REQUIRED)
3. Run tests: `./tools/test.ps1`
4. Run linter: `./tools/lint.ps1`
5. Commit changes
6. Push to remote

## Best Practices

- Keep functions focused and single-purpose
- Add comment-based help to all public functions
- Use approved PowerShell verbs (Get-, Set-, New-, etc.)
- Follow the existing code style and patterns
- Update tests when adding new functionality
- Update README when adding new features or changing usage patterns
