#!/usr/bin/env pwsh
<#
.SYNOPSIS
    General tests for repository structure and script validity.

.DESCRIPTION
    Validates basic repository hygiene: script syntax, required files,
    and that all PowerShell files are parseable.
#>

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
}

Describe 'Repository Structure' {
    It 'Has README.md file' {
        $readmePath = Join-Path $repoRoot 'README.md'
        $readmePath | Should -Exist
    }

    It 'Has .editorconfig file' {
        $editorConfigPath = Join-Path $repoRoot '.editorconfig'
        $editorConfigPath | Should -Exist
    }

    It 'Has PSScriptAnalyzerSettings.psd1 file' {
        $settingsPath = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
        $settingsPath | Should -Exist
    }

    It 'Has tools directory' {
        $toolsPath = Join-Path $repoRoot 'tools'
        $toolsPath | Should -Exist
    }

    It 'Has tests directory' {
        $testsPath = Join-Path $repoRoot 'tests'
        $testsPath | Should -Exist
    }
}

Describe 'PowerShell Scripts Validity' {
    BeforeAll {
        # Find all PowerShell files
        $script:psFiles = @(Get-ChildItem -Path $repoRoot -Include '*.ps1', '*.psm1', '*.psd1' -Recurse -File |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })
    }

    It 'Has PowerShell files in repository' {
        $script:psFiles.Count | Should -BeGreaterThan 0
    }

    Context 'Script Parsing' {
        It 'All PowerShell scripts should parse without errors' {
            $parseErrors = @()
            foreach ($file in $script:psFiles) {
                $errors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors)
                if ($errors.Count -gt 0) {
                    $parseErrors += "$($file.Name): $($errors.Count) error(s)"
                }
            }
            $parseErrors.Count | Should -Be 0 -Because "All scripts should parse without errors. Errors: $($parseErrors -join ', ')"
        }
    }

    Context 'Script Analysis' {
        It 'PSScriptAnalyzer module is available' {
            $hasPSSA = Get-Module -ListAvailable -Name PSScriptAnalyzer
            $hasPSSA | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Tool Scripts' {
    It 'format.ps1 exists and is parseable' {
        $formatScript = Join-Path $repoRoot 'tools/format.ps1'
        $formatScript | Should -Exist

        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($formatScript, [ref]$null, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It 'lint.ps1 exists and is parseable' {
        $lintScript = Join-Path $repoRoot 'tools/lint.ps1'
        $lintScript | Should -Exist

        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($lintScript, [ref]$null, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It 'test.ps1 exists and is parseable' {
        $testScript = Join-Path $repoRoot 'tools/test.ps1'
        $testScript | Should -Exist

        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($testScript, [ref]$null, [ref]$errors)
        $errors.Count | Should -Be 0
    }
}

Describe 'Hello World Test' {
    It 'Proves the Pester test harness works' {
        $true | Should -Be $true
    }

    It 'Can perform basic arithmetic' {
        2 + 2 | Should -Be 4
    }

    It 'PowerShell version is available' {
        $PSVersionTable.PSVersion | Should -Not -BeNullOrEmpty
    }
}
