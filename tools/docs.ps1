#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates documentation for the repository using platyPS.

.DESCRIPTION
    This script generates markdown documentation from comment-based help
    in PowerShell scripts using platyPS module.

.PARAMETER UpdateExisting
    If specified, updates existing documentation files instead of creating new ones.

.EXAMPLE
    .\tools\docs.ps1
    Generates new documentation files.

.EXAMPLE
    .\tools\docs.ps1 -UpdateExisting
    Updates existing documentation files.
#>

[CmdletBinding()]
param(
    [switch]$UpdateExisting
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Get repository root
$repoRoot = Split-Path -Parent $PSScriptRoot

# Ensure platyPS is available
if (-not (Get-Module -ListAvailable -Name platyPS)) {
    Write-Host "platyPS module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name platyPS -Force -Scope CurrentUser -SkipPublisherCheck
}

Import-Module platyPS

# Create docs/reference directory if it doesn't exist
$referencePath = Join-Path $repoRoot 'docs/reference'
if (-not (Test-Path $referencePath)) {
    New-Item -ItemType Directory -Path $referencePath -Force | Out-Null
}

Write-Host "Generating documentation..." -ForegroundColor Cyan
Write-Host "Output directory: $referencePath" -ForegroundColor Gray
Write-Host ""

# Find all PowerShell script files (excluding tools and tests)
$scriptFiles = Get-ChildItem -Path $repoRoot -Include '*.ps1' -File |
    Where-Object {
        $_.FullName -notmatch '[\\/]tools[\\/]' -and
        $_.FullName -notmatch '[\\/]tests[\\/]' -and
        $_.FullName -notmatch '[\\/]\.git[\\/]' -and
        $_.Name -ne 'bootstrap.ps1'
    }

Write-Host "Found $($scriptFiles.Count) script(s) to document" -ForegroundColor Cyan

$documented = 0
$skipped = 0

foreach ($script in $scriptFiles) {
    try {
        $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($script.Name)
        $outputPath = Join-Path $referencePath "$scriptName.md"

        # Check if script has comment-based help using AST
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$null)
        $helpContent = $ast.GetHelpContent()

        if ($helpContent) {
            Write-Host "  Documenting: $($script.Name)" -ForegroundColor Green

            # Generate or update documentation
            if ($UpdateExisting -and (Test-Path $outputPath)) {
                try {
                    Update-MarkdownHelp -Path $outputPath -ErrorAction Stop | Out-Null
                    $documented++
                }
                catch {
                    Write-Host "    ⚠️  Could not update documentation: $_" -ForegroundColor Yellow
                    $skipped++
                }
            }
            else {
                try {
                    # Use Get-Help on the script path - platyPS handles this correctly
                    New-MarkdownHelp -Command $script.FullName -OutputFolder $referencePath -Force -ErrorAction Stop | Out-Null
                    $documented++
                }
                catch {
                    Write-Host "    ⚠️  Could not generate documentation: $_" -ForegroundColor Yellow
                    $skipped++
                }
            }
        }
        else {
            Write-Host "    ⚠️  Skipped: $($script.Name) (no comment-based help)" -ForegroundColor Yellow
            $skipped++
        }
    }
    catch {
        Write-Host "    ❌ Error documenting $($script.Name): $_" -ForegroundColor Red
        $skipped++
    }
}

Write-Host ""
Write-Host "Documentation generation complete!" -ForegroundColor Green
Write-Host "  Documented: $documented" -ForegroundColor Green
Write-Host "  Skipped: $skipped" -ForegroundColor Yellow
Write-Host ""
Write-Host "Documentation available in: $referencePath" -ForegroundColor Cyan
