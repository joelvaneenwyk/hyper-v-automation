#
# HyperVAutomation Module
#
# Collection of PowerShell functions to create Windows, Ubuntu and Debian VMs in Hyper-V.
#

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Get the module root path
$moduleRoot = $PSScriptRoot

# Import private helper functions
$privatePath = Join-Path $moduleRoot 'Private'
if (Test-Path $privatePath) {
    Get-ChildItem -Path $privatePath -Filter '*.ps1' -Recurse | ForEach-Object {
        Write-Verbose "Importing private function from $($_.FullName)"
        . $_.FullName
    }
}

# Import public functions
$publicPath = Join-Path $moduleRoot 'Public'
if (Test-Path $publicPath) {
    Get-ChildItem -Path $publicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        Write-Verbose "Importing public function from $($_.FullName)"
        . $_.FullName
    }
}

# Export only the public functions (defined in the manifest)
# Note: The manifest's FunctionsToExport takes precedence, so we don't need to explicitly call Export-ModuleMember here
