#Requires -RunAsAdministrator

#
# Backward compatibility wrapper for Add-VirtioDrivers
# This script imports the HyperVAutomation module and calls the function.
#
# DEPRECATED: Please import the module directly:
#   Import-Module ./src/HyperVAutomation
#   Add-VirtioDrivers <parameters>
#

# Import the module from src/
$modulePath = Join-Path $PSScriptRoot 'src/HyperVAutomation/HyperVAutomation.psd1'
if (-not (Get-Module HyperVAutomation)) {
    Import-Module $modulePath -Force -ErrorAction Stop
}

# Forward to the module function
Add-VirtioDrivers @args
