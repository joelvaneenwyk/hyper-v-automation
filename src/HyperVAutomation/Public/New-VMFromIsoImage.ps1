function New-VMFromIsoImage {
    <#
    .SYNOPSIS
        Creates a VM and boots it from an ISO image.
    
    .DESCRIPTION
        Creates a Hyper-V Generation 2 VM and boots it from an ISO image.
        Useful for operating systems without cloud-init support.
        Requires administrative privileges.
    
    .PARAMETER IsoPath
        The path to the ISO file.
    
    .PARAMETER VMName
        The name of the virtual machine to create.
    
    .PARAMETER VHDXSizeBytes
        The size of the VHDX file in bytes. Default is 120GB.
    
    .PARAMETER MemoryStartupBytes
        The startup memory in bytes. Default is 1GB.
    
    .PARAMETER EnableDynamicMemory
        If specified, enables dynamic memory.
    
    .PARAMETER ProcessorCount
        The number of virtual processors. Default is 2.
    
    .PARAMETER SwitchName
        The name of the Hyper-V switch. Default is 'SWITCH'.
    
    .PARAMETER MacAddress
        Optional MAC address for the network adapter.
    
    .PARAMETER InterfaceName
        The network interface name. Default is 'eth0'.
    
    .PARAMETER VlanId
        Optional VLAN ID for the primary network adapter.
    
    .PARAMETER SecondarySwitchName
        Optional name of a second Hyper-V switch.
    
    .PARAMETER SecondaryMacAddress
        Optional MAC address for the secondary network adapter.
    
    .PARAMETER SecondaryInterfaceName
        The secondary network interface name.
    
    .PARAMETER SecondaryVlanId
        Optional VLAN ID for the secondary network adapter.
    
    .PARAMETER EnableSecureBoot
        If specified, enables Secure Boot.
    
    .OUTPUTS
        Microsoft.HyperV.PowerShell.VirtualMachine
        Returns the VirtualMachine created.
    
    .EXAMPLE
        New-VMFromIsoImage -IsoPath "C:\opnsense.iso" -VMName "Router01" -VHDXSizeBytes 60GB
        Creates a VM named Router01 and boots from the ISO.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$IsoPath,
        
        [Parameter(Mandatory = $true)]
        [string]$VMName,

        [uint64]$VHDXSizeBytes = 120GB,

        [int64]$MemoryStartupBytes = 1GB,

        [switch]$EnableDynamicMemory,

        [int64]$ProcessorCount = 2,

        [string]$SwitchName = 'SWITCH',

        [string]$MacAddress,

        [string]$InterfaceName = 'eth0',

        [string]$VlanId,

        [string]$SecondarySwitchName,

        [string]$SecondaryMacAddress,

        [string]$SecondaryInterfaceName,

        [string]$SecondaryVlanId,

        [switch]$EnableSecureBoot
    )

    #Requires -RunAsAdministrator

    $ErrorActionPreference = 'Stop'

    function Normalize-MacAddress ([string]$value) {
        $value.`
            Replace('-', '').`
            Replace(':', '').`
            Insert(2, ':').Insert(5, ':').Insert(8, ':').Insert(11, ':').Insert(14, ':').`
            ToLowerInvariant()
    }

    # Get default VHD path (requires administrative privileges)
    $vmmsSettings = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_VirtualSystemManagementServiceSettingData
    $vhdxPath = Join-Path $vmmsSettings.DefaultVirtualHardDiskPath "$VMName.vhdx"

    # Create VM
    Write-Verbose 'Creating VM...'
    $vm = New-VM -Name $VMName -Generation 2 -MemoryStartupBytes $MemoryStartupBytes -NewVHDPath $vhdxPath -NewVHDSizeBytes $VHDXSizeBytes -SwitchName $SwitchName
    $vm | Set-VMProcessor -Count $ProcessorCount
    $vm | Get-VMIntegrationService -Name "Guest Service Interface" | Enable-VMIntegrationService
    $vm | Set-VMMemory -DynamicMemoryEnabled:$EnableDynamicMemory.IsPresent

    # Adds DVD with image
    $dvd = $vm | Add-VMDvdDrive -Path $IsoPath -Passthru
    $vm | Set-VMFirmware -FirstBootDevice $dvd

    if ($EnableSecureBoot.IsPresent) {
        # Sets Secure Boot Template.
        #   Set-VMFirmware -SecureBootTemplate 'MicrosoftUEFICertificateAuthority' doesn't work anymore (!?).
        $vm | Set-VMFirmware -SecureBootTemplateId ([guid]'272e7447-90a4-4563-a4b9-8e4ab00526ce')
    }
    else {
        # Disables Secure Boot.
        $vm | Set-VMFirmware -EnableSecureBoot:Off
    }

    # Setup first network adapter
    if ($MacAddress) {
        $MacAddress = Normalize-MacAddress $MacAddress
        $vm | Set-VMNetworkAdapter -StaticMacAddress $MacAddress.Replace(':', '')
    }
    $eth0 = Get-VMNetworkAdapter -VMName $VMName 
    $eth0 | Rename-VMNetworkAdapter -NewName $InterfaceName
    if ($VlanId) {
        $eth0 | Set-VMNetworkAdapterVlan -Access -VlanId $VlanId
    }    
    if ($SecondarySwitchName) {
        # Add secondary network adapter
        $eth1 = Add-VMNetworkAdapter -VMName $VMName -Name $SecondaryInterfaceName -SwitchName $SecondarySwitchName -Passthru

        if ($SecondaryMacAddress) {
            $SecondaryMacAddress = Normalize-MacAddress $SecondaryMacAddress
            $eth1 | Set-VMNetworkAdapter -StaticMacAddress $SecondaryMacAddress.Replace(':', '')
            if ($SecondaryVlanId) {
                $eth1 | Set-VMNetworkAdapterVlan -Access -VlanId $SecondaryVlanId
            }    

        }
    }

    # Disable Automatic Checkpoints. Check if command is available since it doesn't exist in Server 2016.
    $command = Get-Command Set-VM
    if ($command.Parameters.AutomaticCheckpointsEnabled) {
        $vm | Set-VM -AutomaticCheckpointsEnabled $false
    }

    # Wait for VM
    $vm | Start-VM
    Write-Verbose 'Waiting for VM integration services (1)...'
    Wait-VM -Name $VMName -For Heartbeat

    Write-Verbose 'All done!'
    Write-Verbose 'After finished, please remember to remove the installation media with:'
    Write-Verbose "    Get-VMDvdDrive -VMName '$VMName' | Remove-VMDvdDrive"

    # Return the VM created.
    $vm
}
