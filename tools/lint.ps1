#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs PSScriptAnalyzer static analysis on all PowerShell files.

.DESCRIPTION
    This script runs Invoke-ScriptAnalyzer on all *.ps1, *.psm1, and *.psd1 files
    in the repository using settings from PSScriptAnalyzerSettings.psd1.

.PARAMETER FailOnWarning
    If specified, treats warnings as errors and fails the script.
    By default, only errors cause failure.

.EXAMPLE
    .\tools\lint.ps1
    Runs linting on all PowerShell files.

.EXAMPLE
    .\tools\lint.ps1 -FailOnWarning
    Runs linting and fails on warnings (strict mode for CI).
#>

[CmdletBinding()]
param(
    [switch]$FailOnWarning
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

Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Cyan
Write-Host "Repository: $repoRoot" -ForegroundColor Gray
Write-Host "Settings: $settingsPath" -ForegroundColor Gray
Write-Host ""

# Run PSScriptAnalyzer
$results = Invoke-ScriptAnalyzer -Path $repoRoot -Recurse -Settings $settingsPath -ExcludeRule PSReviewUnusedParameter

# Group results by severity
$errors = $results | Where-Object Severity -eq 'Error'
$warnings = $results | Where-Object Severity -eq 'Warning'
$informational = $results | Where-Object Severity -eq 'Information'

# Display results
Write-Host "Analysis Results:" -ForegroundColor Cyan
Write-Host "  Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -eq 0) { 'Green' } else { 'Red' })
Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "  Information: $($informational.Count)" -ForegroundColor Gray
Write-Host ""

# Display errors
if ($errors.Count -gt 0) {
    Write-Host "ERRORS:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  ❌ $($error.ScriptName):$($error.Line)" -ForegroundColor Red
        Write-Host "     [$($error.RuleName)] $($error.Message)" -ForegroundColor Red
        Write-Host ""
    }
}

# Display warnings
if ($warnings.Count -gt 0) {
    Write-Host "WARNINGS:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  ⚠️  $($warning.ScriptName):$($warning.Line)" -ForegroundColor Yellow
        Write-Host "     [$($warning.RuleName)] $($warning.Message)" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Display informational messages
if ($informational.Count -gt 0 -and $VerbosePreference -eq 'Continue') {
    Write-Host "INFORMATIONAL:" -ForegroundColor Gray
    foreach ($info in $informational) {
        Write-Host "  ℹ️  $($info.ScriptName):$($info.Line)" -ForegroundColor Gray
        Write-Host "     [$($info.RuleName)] $($info.Message)" -ForegroundColor Gray
        Write-Host ""
    }
}

# Determine exit code
$exitCode = 0

if ($errors.Count -gt 0) {
    Write-Host "❌ Analysis failed with $($errors.Count) error(s)" -ForegroundColor Red
    $exitCode = 1
} elseif ($FailOnWarning -and $warnings.Count -gt 0) {
    Write-Host "❌ Analysis failed with $($warnings.Count) warning(s) (strict mode)" -ForegroundColor Red
    $exitCode = 1
} else {
    Write-Host "✓ Analysis passed!" -ForegroundColor Green
}

exit $exitCode
