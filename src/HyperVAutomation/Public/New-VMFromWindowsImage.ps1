function New-VMFromWindowsImage {
    <#
    .SYNOPSIS
        Creates a Windows VM from an ISO image.
    
    .DESCRIPTION
        Creates a Hyper-V Generation 2 VM from a Windows ISO image with unattended setup.
        Requires administrative privileges.
    
    .PARAMETER SourcePath
        The path to the Windows ISO file.
    
    .PARAMETER Edition
        The Windows edition to install. Use Get-WindowsImage to see available images.
    
    .PARAMETER VMName
        The name of the virtual machine to create.
    
    .PARAMETER VHDXSizeBytes
        The size of the VHDX in bytes.
    
    .PARAMETER AdministratorPassword
        The administrator password.
    
    .PARAMETER Version
        The Windows version (required for product key).
    
    .PARAMETER MemoryStartupBytes
        The startup memory in bytes.
    
    .PARAMETER EnableDynamicMemory
        If specified, enables dynamic memory.
    
    .PARAMETER VMProcessorCount
        The number of virtual processors. Default is 2.
    
    .PARAMETER VMSwitchName
        The name of the Hyper-V switch. Default is 'SWITCH'.
    
    .PARAMETER VMMacAddress
        Optional MAC address for the network adapter.
    
    .PARAMETER Locale
        The locale to use. Default is en-US.
    
    .OUTPUTS
        Microsoft.HyperV.PowerShell.VirtualMachine
        Returns the VirtualMachine created.
    
    .EXAMPLE
        New-VMFromWindowsImage -SourcePath "C:\server.iso" -Edition "Windows Server 2022 Standard" -VMName "Server01" -VHDXSizeBytes 60GB -AdministratorPassword "P@ssw0rd!" -Version "Server2022Standard" -MemoryStartupBytes 2GB
        Creates a Windows Server 2022 VM.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$Edition,

        [Parameter(Mandatory = $true)]
        [string]$VMName,

        [Parameter(Mandatory = $true)]
        [uint64]$VHDXSizeBytes,

        [Parameter(Mandatory = $true)]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'Password is passed through to New-VHDXFromWindowsImage for unattend.xml encoding')]
        [string]$AdministratorPassword,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Server2025Datacenter',
            'Server2025Standard',
            'Server2022Datacenter',
            'Server2022Standard',
            'Server2019Datacenter',
            'Server2019Standard',
            'Server2016Datacenter',
            'Server2016Standard',
            'Windows11Enterprise',
            'Windows11Professional',
            'Windows10Enterprise',
            'Windows10Professional',
            'Windows81Professional')]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [int64]$MemoryStartupBytes,

        [switch]$EnableDynamicMemory,

        [int64]$VMProcessorCount = 2,

        [string]$VMSwitchName = 'SWITCH',

        [string]$VMMacAddress,

        [string]$Locale = 'en-US'
    )


    $ErrorActionPreference = 'Stop'

    # Get default VHD path (requires administrative privileges)
    $vmmsSettings = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_VirtualSystemManagementServiceSettingData
    $vhdxPath = Join-Path $vmmsSettings.DefaultVirtualHardDiskPath "$VMName.vhdx"

    # Create VHDX from ISO image
    New-VHDXFromWindowsImage -SourcePath $SourcePath -Edition $Edition -ComputerName $VMName -VHDXSizeBytes $VHDXSizeBytes -VHDXPath $vhdxPath -AdministratorPassword $AdministratorPassword -Version $Version -Locale $Locale

    # Create VM
    Write-Verbose 'Creating VM...'
    $vm = New-VM -Name $VMName -Generation 2 -MemoryStartupBytes $MemoryStartupBytes -VHDPath $vhdxPath -SwitchName $VMSwitchName
    $vm | Set-VMProcessor -Count $VMProcessorCount
    $vm | Get-VMIntegrationService |
        Where-Object { $_ -is [Microsoft.HyperV.PowerShell.GuestServiceInterfaceComponent] } |
        Enable-VMIntegrationService -Passthru
    $vm | Set-VMMemory -DynamicMemoryEnabled:$EnableDynamicMemory.IsPresent

    if ($VMMacAddress) {
        $vm | Set-VMNetworkAdapter -StaticMacAddress ($VMMacAddress -replace ':', '')
    }
    # Disable Automatic Checkpoints (doesn't exist in Server 2016)
    $command = Get-Command Set-VM
    if ($command.Parameters.AutomaticCheckpointsEnabled) {
        $vm | Set-VM -AutomaticCheckpointsEnabled $false
    }
    $vm | Start-VM

    # Wait for installation complete
    Write-Verbose 'Waiting for VM integration services...'
    Wait-VM -Name $vmName -For Heartbeat

    # Return the VM created.
    Write-Verbose 'All done!'
    $vm
}
