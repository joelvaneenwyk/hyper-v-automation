#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Formats all PowerShell files in the repository using PSScriptAnalyzer.

.DESCRIPTION
    This script uses Invoke-Formatter from PSScriptAnalyzer to format all
    *.ps1, *.psm1, and *.psd1 files according to the settings defined in
    PSScriptAnalyzerSettings.psd1.

.PARAMETER Check
    If specified, only checks if files need formatting without modifying them.
    Returns exit code 1 if any files need formatting, 0 if all files are formatted.

.EXAMPLE
    .\tools\format.ps1
    Formats all PowerShell files in the repository.

.EXAMPLE
    .\tools\format.ps1 -Check
    Checks if any files need formatting (used in CI).
#>

[CmdletBinding()]
param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Get repository root
$repoRoot = Split-Path -Parent $PSScriptRoot

# Ensure PSScriptAnalyzer is available
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "PSScriptAnalyzer module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -SkipPublisherCheck
}

Import-Module PSScriptAnalyzer

# Get settings file
$settingsPath = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
if (-not (Test-Path $settingsPath)) {
    throw "Settings file not found at: $settingsPath"
}

# Find all PowerShell files
$filesToFormat = Get-ChildItem -Path $repoRoot -Include '*.ps1', '*.psm1', '*.psd1' -Recurse -File |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.FullName -notmatch '[\\/]node_modules[\\/]' }

Write-Host "Found $($filesToFormat.Count) PowerShell files to process" -ForegroundColor Cyan

$needsFormatting = @()

foreach ($file in $filesToFormat) {
    Write-Verbose "Processing: $($file.FullName)"

    # Read original content
    $originalContent = Get-Content -Path $file.FullName -Raw

    # Format the file
    $formattedContent = Invoke-Formatter -ScriptDefinition $originalContent -Settings $settingsPath

    # Check if content changed
    if ($originalContent -ne $formattedContent) {
        $needsFormatting += $file

        if ($Check) {
            Write-Host "  ❌ $($file.FullName.Replace($repoRoot, '.'))" -ForegroundColor Red
        } else {
            Write-Host "  ✓ Formatted: $($file.FullName.Replace($repoRoot, '.'))" -ForegroundColor Green
            # Write formatted content back
            Set-Content -Path $file.FullName -Value $formattedContent -NoNewline
        }
    } else {
        Write-Verbose "  Already formatted: $($file.FullName)"
    }
}

Write-Host ""

if ($needsFormatting.Count -eq 0) {
    Write-Host "✓ All files are properly formatted!" -ForegroundColor Green
    exit 0
} else {
    if ($Check) {
        Write-Host "❌ $($needsFormatting.Count) file(s) need formatting:" -ForegroundColor Red
        $needsFormatting | ForEach-Object {
            Write-Host "   - $($_.FullName.Replace($repoRoot, '.'))" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "Run './tools/format.ps1' locally to fix formatting issues." -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "✓ Formatted $($needsFormatting.Count) file(s)" -ForegroundColor Green
        exit 0
    }
}
