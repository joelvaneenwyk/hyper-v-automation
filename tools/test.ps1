#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs Pester tests for the repository.

.DESCRIPTION
    This script runs all Pester tests in the tests/ folder and generates
    reports suitable for CI/CD pipelines.

.PARAMETER OutputFormat
    The output format for test results. Default is 'NUnitXml'.
    Options: NUnitXml, JUnitXml, Console

.PARAMETER OutputFile
    The file path for test results output. Default is 'TestResults.xml'.

.PARAMETER CodeCoverage
    If specified, generates code coverage report.

.PARAMETER MinimumCoverage
    Minimum code coverage percentage required (0-100). Only applies if CodeCoverage is specified.

.EXAMPLE
    .\tools\test.ps1
    Runs all tests with default settings.

.EXAMPLE
    .\tools\test.ps1 -CodeCoverage -MinimumCoverage 80
    Runs tests with code coverage and requires 80% coverage.
#>

[CmdletBinding()]
param(
    [ValidateSet('NUnitXml', 'JUnitXml', 'Console')]
    [string]$OutputFormat = 'NUnitXml',

    [string]$OutputFile = 'TestResults.xml',

    [switch]$CodeCoverage,

    [ValidateRange(0, 100)]
    [int]$MinimumCoverage = 0
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Get repository root
$repoRoot = Split-Path -Parent $PSScriptRoot

# Ensure Pester is available (v5.x)
$pesterModule = Get-Module -ListAvailable -Name Pester | Where-Object Version -GE '5.0.0' | Select-Object -First 1

if (-not $pesterModule) {
    Write-Host "Pester 5.x not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -Scope CurrentUser -SkipPublisherCheck
}

Import-Module Pester -MinimumVersion 5.0.0

# Configure Pester
$configuration = New-PesterConfiguration

# Test discovery
$configuration.Run.Path = Join-Path $repoRoot 'tests'
$configuration.Run.PassThru = $true

# Output configuration
$configuration.Output.Verbosity = 'Detailed'

# Test result output
if ($OutputFormat -ne 'Console') {
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputFormat = $OutputFormat
    $configuration.TestResult.OutputPath = Join-Path $repoRoot $OutputFile
}

# Code coverage configuration
if ($CodeCoverage) {
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = @(
        (Join-Path $repoRoot '*.ps1')
        (Join-Path $repoRoot '*.psm1')
    )
    $configuration.CodeCoverage.OutputFormat = 'JaCoCo'
    $configuration.CodeCoverage.OutputPath = Join-Path $repoRoot 'coverage.xml'
}

Write-Host "Running Pester tests..." -ForegroundColor Cyan
Write-Host "Test Path: $($configuration.Run.Path)" -ForegroundColor Gray
Write-Host ""

# Run tests
$result = Invoke-Pester -Configuration $configuration

Write-Host ""
Write-Host "Test Results:" -ForegroundColor Cyan
Write-Host "  Total: $($result.TotalCount)" -ForegroundColor Gray
Write-Host "  Passed: $($result.PassedCount)" -ForegroundColor Green
Write-Host "  Failed: $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { 'Green' } else { 'Red' })
Write-Host "  Skipped: $($result.SkippedCount)" -ForegroundColor Yellow
Write-Host "  NotRun: $($result.NotRunCount)" -ForegroundColor Gray
Write-Host ""

# Handle code coverage
if ($CodeCoverage) {
    $coveragePercent = [math]::Round($result.CodeCoverage.CoveragePercent, 2)
    Write-Host "Code Coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge $MinimumCoverage) { 'Green' } else { 'Red' })

    if ($coveragePercent -lt $MinimumCoverage) {
        Write-Host "❌ Code coverage $coveragePercent% is below minimum $MinimumCoverage%" -ForegroundColor Red
        exit 1
    }
}

# Exit with appropriate code
if ($result.FailedCount -eq 0) {
    Write-Host "✓ All tests passed!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "❌ $($result.FailedCount) test(s) failed" -ForegroundColor Red
    exit 1
}
