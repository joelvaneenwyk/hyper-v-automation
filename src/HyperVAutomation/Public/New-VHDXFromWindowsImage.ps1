function New-VHDXFromWindowsImage {
    <#
    .SYNOPSIS
        Creates a Windows VHDX from an ISO image.
    
    .DESCRIPTION
        Creates a Windows VHDX from an ISO image with an unattended setup.
        Similar to New-VMFromWindowsImage but without creating a VM.
        Requires administrative privileges and Windows PowerShell (Desktop edition).
    
    .PARAMETER SourcePath
        The path to the Windows ISO file.
    
    .PARAMETER Edition
        The Windows edition to install.
    
    .PARAMETER ComputerName
        The computer name for the VM.
    
    .PARAMETER VHDXPath
        The path for the VHDX file. If not specified, uses current directory.
    
    .PARAMETER VHDXSizeBytes
        The size of the VHDX in bytes. Default is 120GB.
    
    .PARAMETER AdministratorPassword
        The administrator password. If not specified, a random password is generated.
    
    .PARAMETER Version
        The Windows version (required for product key).
    
    .PARAMETER Locale
        The locale to use. Default is en-US.
    
    .PARAMETER AddVirtioDrivers
        The path to VirtIO ISO file to add VirtIO drivers and QEMU Guest Agent.
    
    .OUTPUTS
        System.String
        Returns the path to the created VHDX file.
    
    .EXAMPLE
        New-VHDXFromWindowsImage -SourcePath "C:\server.iso" -Edition "Windows Server 2022 Standard" -Version "Server2022Standard" -VHDXSizeBytes 60GB
        Creates a VHDX from the ISO.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$Edition,

        [string]$ComputerName,

        [string]$VHDXPath,

        [uint64]$VHDXSizeBytes,

        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'Password is passed to New-WindowsUnattendFile which encodes it for XML')]
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

        [string]$Locale = 'en-US',

        [string]$AddVirtioDrivers
    )


    $ErrorActionPreference = 'Stop'

    if (-not $VHDXPath) {
        # Resolve path that might not exist -- https://stackoverflow.com/a/3040982
        $VHDXPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\$($ComputerName).vhdx")
    }

    if (-not $VHDXSizeBytes) {
        $VHDXSizeBytes = 120GB
    }

    if (-not $AdministratorPassword) {
        # Random password
        $AdministratorPassword = -join (
            (65..90) + (97..122) + (48..57) |
                Get-Random -Count 16 |
                ForEach-Object { [char]$_ }
        )
    }

    # Create unattend.xml
    $unattendPath = New-WindowsUnattendFile -AdministratorPassword $AdministratorPassword -Version $Version -ComputerName $ComputerName -Locale $Locale -AddVirtioDrivers:(!!$AddVirtioDrivers)

    # Create VHDX from ISO image
    Write-Verbose 'Creating VHDX from image...'

    # Create temporary folder to store files to be merged into the VHDX.
    $mergeFolder = Join-Path $env:TEMP 'New-VHDXFromWindowsImage-root'
    if (Test-Path $mergeFolder) {
        Remove-Item -Recurse -Force $mergeFolder
    }
    New-Item -ItemType Directory -Path $mergeFolder -Force > $null

    $cwiArguments = @{
        SourcePath = $SourcePath
        Edition = $Edition
        VHDPath = $vhdxPath
        SizeBytes = $VHDXSizeBytes
        VHDFormat = 'VHDX'
        DiskLayout = 'UEFI'
        UnattendPath = $unattendPath
        MergeFolder = $mergeFolder
    }

    # Removes unattend.xml files after the setup is complete.
    #   https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-a-custom-script-to-windows-setup#run-a-script-after-setup-is-complete-setupcompletecmd
    $scriptsFolder = Join-Path $mergeFolder '\Windows\Setup\Scripts'
    New-Item -ItemType Directory -Path $scriptsFolder -Force > $null
    @'
DEL /Q /F C:\Windows\Panther\unattend.xml
DEL /Q /F C:\unattend.xml
'@ | Out-File "$scriptsFolder\SetupComplete.cmd" -Encoding ascii

    $driversFolder = Join-Path $mergeFolder '\Windows\drivers'
    New-Item -ItemType Directory -Path $driversFolder -Force > $null

    if ($AddVirtioDrivers) {
        With-IsoImage -IsoFileName $AddVirtioDrivers {
            param($virtioDriveLetter)

            # Throws if the ISO does not contain Virtio drivers.
            $virtioDrivers = Get-VirtioDrivers -VirtioDriveLetter $virtioDriveLetter -Version $Version

            # Adds QEMU Guest Agent installer (will be installed by unattend.xml)
            $msiFile = Get-Item "$($virtioDriveLetter):\guest-agent\qemu-ga-x86_64.msi"
            Copy-Item $msiFile -Destination $driversFolder -Force

            & "$PSScriptRoot\..\Private\Convert-WindowsImage.ps1" @cwiArguments -Driver $virtioDrivers
        }
    }
    else {
        & "$PSScriptRoot\..\Private\Convert-WindowsImage.ps1" @cwiArguments
    }

    $VHDXPath
}
