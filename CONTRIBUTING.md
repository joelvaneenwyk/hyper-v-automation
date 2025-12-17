# Contributing to Hyper-V Automation Scripts

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Development Setup

### Prerequisites

- PowerShell 7.x or later (PowerShell Core)
- Git
- Recommended: Visual Studio Code with PowerShell extension

### Required Modules

The following PowerShell modules are required for development:

- **PSScriptAnalyzer** - For linting and formatting
- **Pester** (v5.x+) - For unit testing
- **platyPS** - For documentation generation (optional)

Install them with:

```powershell
Install-Module -Name PSScriptAnalyzer, Pester, platyPS -Scope CurrentUser -Force
```

## Development Workflow

### 1. Format Your Code

Before committing, format all PowerShell files:

```powershell
./tools/format.ps1
```

To check if files need formatting without modifying them:

```powershell
./tools/format.ps1 -Check
```

### 2. Run Tests

Run all tests with:

```powershell
./tools/test.ps1
```

For code coverage:

```powershell
./tools/test.ps1 -CodeCoverage
```

### 3. Run Linting

Check for code quality issues:

```powershell
./tools/lint.ps1
```

To fail on warnings (strict mode):

```powershell
./tools/lint.ps1 -FailOnWarning
```

### 4. Generate Documentation

Update documentation for all scripts:

```powershell
./tools/docs.ps1
```

To update existing documentation:

```powershell
./tools/docs.ps1 -UpdateExisting
```

## Code Style Guidelines

### Formatting Rules

This project uses PSScriptAnalyzer for code formatting. The configuration is in `PSScriptAnalyzerSettings.psd1`. Key rules:

- **Indentation**: 4 spaces (no tabs)
- **Braces**: Opening brace on same line
- **Line endings**: LF (Unix-style)
- **Encoding**: UTF-8
- **Alignment**: Align assignment statements in hashtables

### Comment-Based Help

All public functions/scripts should include comment-based help with at least:

```powershell
<#
.SYNOPSIS
    Brief description of what the script/function does.

.DESCRIPTION
    Detailed description of functionality.

.PARAMETER ParameterName
    Description of the parameter.

.EXAMPLE
    .\Script-Name.ps1 -Parameter Value
    Description of what this example does.
#>
```

### Naming Conventions

- **Scripts**: Use `Verb-Noun.ps1` format (e.g., `New-VMFromImage.ps1`)
- **Functions**: Use `Verb-Noun` format with approved PowerShell verbs
- **Variables**: Use `$camelCase` or `$PascalCase`
- **Parameters**: Use `$PascalCase`

## Testing Guidelines

### Writing Tests

Tests are written using Pester v5.x and located in the `tests/` directory. Test files must end with `.Tests.ps1`.

Example test structure:

```powershell
Describe 'Feature Name' {
    BeforeAll {
        # Setup code runs once before all tests
    }

    It 'Should do something' {
        $result = Get-Something
        $result | Should -Be 'expected'
    }

    Context 'Specific Scenario' {
        It 'Should handle edge case' {
            # Test edge case
        }
    }
}
```

### Test Coverage

- Aim for meaningful test coverage, not just line coverage
- Test edge cases and error conditions
- Use mocking for external dependencies

## Pull Request Process

1. **Fork** the repository and create a branch from `main`
2. **Make changes** following the code style guidelines
3. **Format** your code with `./tools/format.ps1`
4. **Run tests** with `./tools/test.ps1` - ensure they pass
5. **Run linter** with `./tools/lint.ps1` - fix any issues
6. **Update documentation** if needed
7. **Commit** with a clear, descriptive message
8. **Push** to your fork and submit a pull request

### Pull Request Checklist

- [ ] Code follows the style guidelines
- [ ] All tests pass
- [ ] No linting errors
- [ ] Comment-based help is included for new scripts/functions
- [ ] Documentation is updated if needed
- [ ] Commit messages are clear and descriptive

## Continuous Integration

All pull requests are automatically checked for:

- ✅ **Tests** - All Pester tests must pass
- ✅ **Linting** - No PSScriptAnalyzer errors
- ✅ **Formatting** - Code must be properly formatted

If CI fails, review the logs and fix the issues locally before pushing again.

## Documentation

Documentation is automatically built and deployed to GitHub Pages when changes are merged to `main`. The documentation site is built using MkDocs with the Material theme.

### Local Documentation Preview

To preview documentation locally:

```bash
# Install MkDocs and theme
pip install mkdocs-material mkdocs-awesome-pages-plugin

# Serve documentation locally
mkdocs serve
```

Then open http://localhost:8000 in your browser.

## Getting Help

- **Issues**: Open an issue on GitHub for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Check the [docs site](https://joelvaneenwyk.github.io/hyper-v-automation/)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

Thank you for contributing! 🎉
