function Add-VirtioDrivers {
    <#
    .SYNOPSIS
        Adds Windows VirtIO Drivers into a WIM or VHDX file.
    
    .DESCRIPTION
        Adds Windows VirtIO Drivers into a WIM or VHDX file for use in KVM environments.
        Requires administrative privileges.
    
    .PARAMETER VirtioIsoPath
        The path to the VirtIO ISO file.
    
    .PARAMETER ImagePath
        The path to the WIM or VHDX file.
    
    .PARAMETER Version
        The Windows version of the image (required).
    
    .PARAMETER ImageIndex
        The image index inside the WIM. For VHDX files, must be 1 (default).
    
    .EXAMPLE
        Add-VirtioDrivers -VirtioIsoPath "C:\virtio-win.iso" -ImagePath "C:\image.vhdx" -Version "Server2022Standard"
        Adds VirtIO drivers to the VHDX file.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Function modifies system state but is not interactive')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VirtioIsoPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

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

        [int]$ImageIndex = 1
    )


    $ErrorActionPreference = 'Stop'

    # Reference: https://pve.proxmox.com/wiki/Windows_10_guest_best_practices

    With-IsoImage -IsoFileName $VirtioIsoPath {
        param($virtioDriveLetter)

        # Throws if the ISO does not contain Virtio drivers.
        $virtioDrivers = Get-VirtioDrivers -VirtioDriveLetter $virtioDriveLetter -Version $Version

        With-WindowsImage -ImagePath $ImagePath -ImageIndex $ImageIndex -VirtioDriveLetter $VirtioDriveLetter {
            param($mountPath)

            $virtioDrivers | ForEach-Object {
                Add-WindowsDriver -Path $mountPath -Driver $_ -Recurse -ForceUnsigned > $null
            }
        }
    }
}
