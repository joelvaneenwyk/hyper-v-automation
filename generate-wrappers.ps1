#!/usr/bin/env pwsh
# Generate backward-compatible wrapper scripts for all public functions

$publicFunctions = @(
    'Add-VirtioDrivers'
    'Download-VerifiedFile'
    'Enable-RemoteManagementViaSession'
    'Get-DebianImage'
    'Get-OPNsenseImage'
    'Get-UbuntuImage'
    'Get-VirtioImage'
    'Move-VMOffline'
    'New-VHDXFromWindowsImage'
    'New-VMFromDebianImage'
    'New-VMFromIsoImage'
    'New-VMFromUbuntuImage'
    'New-VMFromWindowsImage'
    'New-VMSession'
    'New-WindowsUnattendFile'
    'Set-NetIPAddressViaSession'
    'Set-NetIPv6AddressViaSession'
)

foreach ($funcName in $publicFunctions) {
    $wrapperPath = "$funcName.ps1"
    
    # Check if original script needs #Requires directives
    $requiresAdmin = @('Add-VirtioDrivers', 'New-VHDXFromWindowsImage', 'New-VMFromDebianImage', 
                       'New-VMFromIsoImage', 'New-VMFromUbuntuImage', 'New-VMFromWindowsImage') -contains $funcName
    $requiresDesktop = @('New-VHDXFromWindowsImage') -contains $funcName
    
    $requires = ""
    if ($requiresAdmin) {
        $requires += "#Requires -RunAsAdministrator`n"
    }
    if ($requiresDesktop) {
        $requires += "#Requires -PSEdition Desktop`n"
    }
    if ($requires) {
        $requires += "`n"
    }
    
    $wrapper = @"
${requires}#
# Backward compatibility wrapper for $funcName
# This script imports the HyperVAutomation module and calls the function.
#
# DEPRECATED: Please import the module directly:
#   Import-Module ./src/HyperVAutomation
#   $funcName <parameters>
#

# Import the module from src/
`$modulePath = Join-Path `$PSScriptRoot 'src/HyperVAutomation/HyperVAutomation.psd1'
if (-not (Get-Module HyperVAutomation)) {
    Import-Module `$modulePath -Force -ErrorAction Stop
}

# Forward to the module function
$funcName @args
"@
    
    Set-Content -Path $wrapperPath -Value $wrapper -Encoding UTF8
    Write-Host "Created wrapper: $wrapperPath"
}
