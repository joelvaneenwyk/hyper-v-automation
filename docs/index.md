# Hyper-V Automation Scripts Documentation

Welcome to the documentation for the Hyper-V Automation Scripts repository!

## Overview

This is a collection of PowerShell scripts to automate the creation and management of Windows, Ubuntu, and Debian VMs in Hyper-V.

**Requirements:**
- Windows Server 2016+ or Windows 10+
- Hyper-V Generation 2 (UEFI) support

## Quick Start

To download all scripts into your `$env:TEMP` folder:

```powershell
iex (iwr 'bit.ly/h-v-a' -UseBasicParsing)
```

## Main Features

### Windows VMs
- Create Windows VMs from ISO images
- Create standalone VHDX files from Windows ISOs
- Configure networking via PowerShell sessions
- Add VirtIO drivers for KVM migration

### Linux VMs
- Create Ubuntu VMs from cloud images
- Create Debian VMs from cloud images
- Configure cloud-init for automated setup
- Support for SSH key authentication

### Other Features
- Download and verify image files
- Move VMs between hosts using Hyper-V replica
- Unattended Windows installation support

## Command Categories

### Setup
- `bootstrap.ps1` - Download and unpack the latest archive

### Windows VM Creation
- `New-VMFromWindowsImage.ps1` - Create a Windows VM from an ISO
- `New-VHDXFromWindowsImage.ps1` - Create a standalone VHDX
- `New-VMSession.ps1` - Create a PowerShell session to a VM
- `Set-NetIPAddressViaSession.ps1` - Configure IPv4 networking
- `Set-NetIPv6AddressViaSession.ps1` - Configure IPv6 networking
- `Enable-RemoteManagementViaSession.ps1` - Enable PowerShell remoting

### Linux VM Creation
- `Get-UbuntuImage.ps1` - Download Ubuntu cloud images
- `New-VMFromUbuntuImage.ps1` - Create an Ubuntu VM
- `Get-DebianImage.ps1` - Download Debian cloud images
- `New-VMFromDebianImage.ps1` - Create a Debian VM

### VirtIO Driver Support
- `Get-VirtioImage.ps1` - Download Windows VirtIO drivers
- `Add-VirtioDrivers.ps1` - Add VirtIO drivers to Windows images

### Other Utilities
- `Download-VerifiedFile.ps1` - Download and verify file integrity
- `Move-VMOffline.ps1` - Move VMs between hosts
- `New-WindowsUnattendFile.ps1` - Create Windows unattend.xml files

## Examples

### Create a Windows Server VM

```powershell
$isoFile = '.\en_windows_server_2019_x64_dvd_4cb967d8.iso'
$vmName = 'TestWindows'
$pass = 'YourStrongPassword!'

.\New-VMFromWindowsImage.ps1 `
    -SourcePath $isoFile `
    -Edition 'Windows Server 2019 Standard' `
    -VMName $vmName `
    -VHDXSizeBytes 60GB `
    -AdministratorPassword $pass `
    -Version 'Server2019Standard' `
    -MemoryStartupBytes 2GB `
    -VMProcessorCount 2
```

### Create an Ubuntu VM

```powershell
$imgFile = .\Get-UbuntuImage.ps1
$vmName = 'TestUbuntu'
$rootPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

.\New-VMFromUbuntuImage.ps1 `
    -SourcePath $imgFile `
    -VMName $vmName `
    -RootPublicKey $rootPublicKey `
    -VHDXSizeBytes 60GB `
    -MemoryStartupBytes 2GB `
    -ProcessorCount 2 `
    -IPAddress 10.10.1.196/16 `
    -Gateway 10.10.1.250 `
    -DnsAddresses '8.8.8.8','8.8.4.4'
```

## Contributing

Contributions are welcome! Please ensure your code:
- Follows PowerShell best practices
- Includes comment-based help
- Passes PSScriptAnalyzer checks
- Includes tests where appropriate

## License

See the repository LICENSE file for details.

## Reference Documentation

For detailed documentation of each script, see the [Reference](reference/) section.
