@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'HyperVAutomation.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = '8f3a5e7c-2b4d-4e8a-9c1f-6d7e8a9b0c1d'

    # Author of this module
    Author = 'Joel Van Eenwyk'

    # Company or vendor of this module
    CompanyName = 'Joel Van Eenwyk'

    # Copyright statement for this module
    Copyright = '(c) Joel Van Eenwyk. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Collection of PowerShell functions to create Windows, Ubuntu and Debian VMs in Hyper-V. Supports Windows Server 2016+, Windows 10+ and Hyper-V Generation 2 (UEFI) VMs only.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    # Note: Hyper-V module is required for most functions but not available on all platforms
    # RequiredModules = @('Hyper-V')

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
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

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Hyper-V', 'Virtualization', 'VM', 'Automation', 'Windows', 'Ubuntu', 'Debian', 'Cloud-Init', 'VirtIO')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/joelvaneenwyk/hyper-v-automation/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/joelvaneenwyk/hyper-v-automation'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial module release with refactored structure. Includes all previous script functionality as module functions.'
        }
    }
}
