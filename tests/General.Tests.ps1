#!/usr/bin/env pwsh
<#
.SYNOPSIS
    General tests for repository structure and script validity.

.DESCRIPTION
    Validates basic repository hygiene: script syntax, required files,
    and that all PowerShell files are parseable.
#>

BeforeAll {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variable is used in Describe blocks, PSScriptAnalyzer does not understand Pester scoping')]
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

    It 'Has src directory' {
        $srcPath = Join-Path $repoRoot 'src'
        $srcPath | Should -Exist
    }

    It 'Has HyperVAutomation module directory' {
        $modulePath = Join-Path $repoRoot 'src/HyperVAutomation'
        $modulePath | Should -Exist
    }

    It 'Has module manifest' {
        $manifestPath = Join-Path $repoRoot 'src/HyperVAutomation/HyperVAutomation.psd1'
        $manifestPath | Should -Exist
    }

    It 'Has root module file' {
        $moduleFilePath = Join-Path $repoRoot 'src/HyperVAutomation/HyperVAutomation.psm1'
        $moduleFilePath | Should -Exist
    }

    It 'Has Public functions directory' {
        $publicPath = Join-Path $repoRoot 'src/HyperVAutomation/Public'
        $publicPath | Should -Exist
    }

    It 'Has Private functions directory' {
        $privatePath = Join-Path $repoRoot 'src/HyperVAutomation/Private'
        $privatePath | Should -Exist
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
            $hasPSSA = Get-Module -ListAvailable -name PSScriptAnalyzer
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

Describe 'Module Structure' {
    BeforeAll {
        $script:manifestPath = Join-Path $repoRoot 'src/HyperVAutomation/HyperVAutomation.psd1'
        $script:modulePath = Join-Path $repoRoot 'src/HyperVAutomation/HyperVAutomation.psm1'
    }

    It 'Module manifest is valid' {
        { Test-ModuleManifest -Path $script:manifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Module can be imported' {
        { Import-Module $script:manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    Context 'Module Functions' {
        BeforeAll {
            Import-Module $script:manifestPath -Force -ErrorAction Stop
        }

        It 'Exports expected number of functions' {
            $exportedFunctions = (Get-Command -Module HyperVAutomation -CommandType Function).Count
            $exportedFunctions | Should -Be 17
        }

        It 'All public functions are exported' {
            $publicFiles = Get-ChildItem -Path (Join-Path $repoRoot 'src/HyperVAutomation/Public') -Filter '*.ps1' -File
            $exportedCommands = Get-Command -Module HyperVAutomation -CommandType Function

            foreach ($file in $publicFiles) {
                $functionName = $file.BaseName
                $exportedCommands.Name | Should -Contain $functionName -Because "Function $functionName should be exported"
            }
        }

        It 'Can call Get-Command with module name' {
            $commands = Get-Command -Module HyperVAutomation
            $commands | Should -Not -BeNullOrEmpty
        }

        AfterAll {
            Remove-Module HyperVAutomation -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Wrapper Scripts' {
    BeforeAll {
        $script:wrapperScripts = Get-ChildItem -Path $repoRoot -Filter '*.ps1' -File | 
            Where-Object { $_.Name -notmatch '^(bootstrap|generate-wrappers)\.ps1$' }
    }

    It 'Has wrapper scripts at root' {
        $script:wrapperScripts.Count | Should -BeGreaterThan 0
    }

    It 'All wrapper scripts are parseable' {
        foreach ($wrapper in $script:wrapperScripts) {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($wrapper.FullName, [ref]$null, [ref]$errors)
            $errors.Count | Should -Be 0 -Because "$($wrapper.Name) should parse without errors"
        }
    }
}
