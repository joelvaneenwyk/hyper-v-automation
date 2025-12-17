# Hyper-V automation scripts

[![CI](https://github.com/joelvaneenwyk/hyper-v-automation/actions/workflows/ci.yml/badge.svg)](https://github.com/joelvaneenwyk/hyper-v-automation/actions/workflows/ci.yml)
[![Documentation](https://github.com/joelvaneenwyk/hyper-v-automation/actions/workflows/pages.yml/badge.svg)](https://joelvaneenwyk.github.io/hyper-v-automation/)

Collection of Powershell scripts to create Windows, Ubuntu and Debian VMs in Hyper-V.

For Windows Server 2016+, Windows 10+ only.

For Hyper-V Generation 2 (UEFI) VMs only.

To migrate an existing Windows VM from Hyper-V to Proxmox (QEMU) see [Prepare a VHDX for QEMU migration](#prepare-a-vhdx-for-qemu-migration).

## Documentation

📚 [Full documentation](https://joelvaneenwyk.github.io/hyper-v-automation/) is available on GitHub Pages.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Code formatting and style
- Running tests and linting
- Documentation
- Pull request process

## How to install

To download all scripts into your `$env:TEMP` folder:

```powershell
iex (iwr 'bit.ly/h-v-a' -UseBasicParsing)
```

If you already cloned the repo, you can refresh from GitHub with [bootstrap.ps1](bootstrap.ps1): it downloads the current archive into `%TEMP%`, extracts it, and switches the working directory to the extracted folder.

# Examples

## Create a new VM for Hyper-V

```powershell
$isoFile = '.\en_windows_server_2019_x64_dvd_4cb967d8.iso'
$vmName = 'TstWindows'
$pass = 'u531@rg3pa55w0rd$!'

.\New-VMFromWindowsImage.ps1 `
    -SourcePath $isoFile `
    -Edition 'Windows Server 2019 Standard' `
    -VMName $vmName `
    -VHDXSizeBytes 60GB `
    -AdministratorPassword $pass `
    -Version 'Server2019Standard' `
    -MemoryStartupBytes 2GB `
    -VMProcessorCount 2

$sess = .\New-VMSession.ps1 -VMName $vmName -AdministratorPassword $pass

.\Set-NetIPAddressViaSession.ps1 `
    -Session $sess `
    -IPAddress 10.10.1.195 `
    -PrefixLength 16 `
    -DefaultGateway 10.10.1.250 `
    -DnsAddresses '8.8.8.8','8.8.4.4' `
    -NetworkCategory 'Public'

.\Enable-RemoteManagementViaSession.ps1 -Session $sess

# You can run any commands on VM with Invoke-Command:
Invoke-Command -Session $sess {
    echo "Hello, world! (from $env:COMPUTERNAME)"

    # Install chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Install 7-zip
    choco install 7zip -y
}

Remove-PSSession -Session $sess
```

## Prepare a VHDX for QEMU migration

```powershell
$vmName = 'TstWindows'

# Shutdown VM
Stop-VM $vmName

# Get VirtIO ISO
$virtioIso = .\Get-VirtioImage.ps1 -OutputPath $env:TEMP

# Install VirtIO drivers to Windows VM (offline)
$vhdxFile = "C:\Hyper-V\Virtual Hard Disks\$vmName.vhdx"
.\Add-VirtioDrivers.ps1 -VirtioIsoPath $virtioIso -ImagePath $vhdxFile

# Copy VHDX file to QEMU host
scp $vhdxFile "root@pve-host:/tmp/"
```

After the copy is complete, you may use [`import-vm-windows`](https://github.com/fdcastel/Proxmox-Automation#import-vm-windows) on Proxmox to import the `vhdx` file and create the Windows VM.

Once the VM is running, ensure that the [QEMU Guest Agent](https://pve.proxmox.com/wiki/Qemu-guest-agent) is installed within the guest environment.

# Command summary

- Setup
  - [bootstrap.ps1](bootstrap.ps1) — download and unpack the latest archive into `%TEMP%`
- For Windows VMs
  - [New-VMFromWindowsImage.ps1](New-VMFromWindowsImage.ps1) — see [details](#new-vmfromwindowsimage-) (*)
  - [New-VHDXFromWindowsImage.ps1](New-VHDXFromWindowsImage.ps1) — see [details](#new-vhdxfromwindowsimage-) (*)
  - [New-VMSession.ps1](New-VMSession.ps1) — see [details](#new-vmsession)
  - [Set-NetIPAddressViaSession.ps1](Set-NetIPAddressViaSession.ps1) — see [details](#set-netipaddressviasession)
  - [Set-NetIPv6AddressViaSession.ps1](Set-NetIPv6AddressViaSession.ps1) — see [details](#set-netipv6addressviasession)
  - [Get-VirtioImage.ps1](Get-VirtioImage.ps1) — see [details](#get-virtioimage)
  - [Add-VirtioDrivers.ps1](Add-VirtioDrivers.ps1) — see [details](#add-virtiodrivers)
  - [Enable-RemoteManagementViaSession.ps1](Enable-RemoteManagementViaSession.ps1) — see [details](#enable-remotemanagementviasession)
- For Ubuntu VMs
  - [Get-UbuntuImage.ps1](Get-UbuntuImage.ps1) — see [details](#get-ubuntuimage)
  - [New-VMFromUbuntuImage.ps1](New-VMFromUbuntuImage.ps1) — see [details](#new-vmfromubuntuimage-) (*)
- For Debian VMs
  - [Get-DebianImage.ps1](Get-DebianImage.ps1) — see [details](#get-debianimage)
  - [New-VMFromDebianImage.ps1](New-VMFromDebianImage.ps1) — see [details](#new-vmfromdebianimage-) (*)
- For images with no `cloud-init` support
  - [Get-OPNsenseImage.ps1](Get-OPNsenseImage.ps1) — see [details](#get-opnsenseimage)
  - [New-VMFromIsoImage.ps1](New-VMFromIsoImage.ps1) — see [details](#new-vmfromisoimage-) (*)
- Other commands
  - [Download-VerifiedFile.ps1](Download-VerifiedFile.ps1) — see [details](#download-verifiedfile)
  - [Move-VMOffline.ps1](Move-VMOffline.ps1) — see [details](#move-vmoffline)
- Helpers and tools
  - [New-WindowsUnattendFile.ps1](New-WindowsUnattendFile.ps1) — see [details](#new-windowsunattendfile)
  - [tools/Convert-WindowsImage.ps1](tools/Convert-WindowsImage.ps1) — see [details](#convert-windowsimage)
  - [tools/Metadata-Functions.ps1](tools/Metadata-Functions.ps1) — see [details](#metadata-functions)
  - [tools/Virtio-Functions.ps1](tools/Virtio-Functions.ps1) — see [details](#virtio-functions)

**(*) Requires administrative privileges**.

# bootstrap.ps1

Script: [bootstrap.ps1](bootstrap.ps1)

Downloads the latest master ZIP from GitHub into `%TEMP%`, extracts it, and changes the working directory to the extracted folder. Run it when you want a fresh copy of all scripts without cloning the repo.

# For Windows VMs

## New-VMFromWindowsImage (*)

Script: [New-VMFromWindowsImage.ps1](New-VMFromWindowsImage.ps1)

```powershell
New-VMFromWindowsImage.ps1 [-SourcePath] <string> [-Edition] <string> [-VMName] <string> [-VHDXSizeBytes] <uint64> [-AdministratorPassword] <string> [-Version] <string> [-MemoryStartupBytes] <long> [[-VMProcessorCount] <long>] [[-VMSwitchName] <string>] [[-VMMacAddress] <string>] [[-Locale] <string>] [-EnableDynamicMemory] [<CommonParameters>]
```

Creates a Windows VM from an ISO image.

For the `-Edition` parameter use `Get-WindowsImage -ImagePath <path-to-install.wim>` to see all available images. Or just use "1" for the first one.

The `-Version` parameter is required to set the product key (required for a full unattended install).

Returns the `VirtualMachine` created.

**(*) Requires administrative privileges**.

## New-VHDXFromWindowsImage (*)

Script: [New-VHDXFromWindowsImage.ps1](New-VHDXFromWindowsImage.ps1)

```powershell
New-VHDXFromWindowsImage.ps1 [-SourcePath] <string> [-Edition] <string> [[-ComputerName] <string>] [[-VHDXPath] <string>] [[-VHDXSizeBytes] <uint64>] [[-AdministratorPassword] <string>] [-Version] <string> [[-Locale] <string>] [[-AddVirtioDrivers] <string>] [<CommonParameters>]
```

Creates a Windows VHDX from an ISO image. Similar to [New-VMFromWindowsImage.ps1](New-VMFromWindowsImage.ps1) but without creating a VM.

You can add [Windows VirtIO Drivers](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers) and the [QEMU Guest Agent](https://pve.proxmox.com/wiki/Qemu-guest-agent) with `-AddVirtioDrivers`. In this case you must provide the path of VirtIO ISO (see [Get-VirtioImage.ps1](#get-virtioimage)) to this parameter. This is useful if you wish to import the created VHDX in a KVM environment.

Returns the path for the VHDX file created.

**(*) Requires administrative privileges**.

## New-VMSession

Script: [New-VMSession.ps1](New-VMSession.ps1)

```powershell
New-VMSession.ps1 [-VMName] <string> [-AdministratorPassword] <string> [[-DomainName] <string>] [<CommonParameters>]
```

Creates a new `PSSession` into a VM. In case of error, keeps retrying until connected. Useful for wait until a VM is ready to accept commands.

Returns the `PSSession` created.

## Set-NetIPAddressViaSession

Script: [Set-NetIPAddressViaSession.ps1](Set-NetIPAddressViaSession.ps1)

```powershell
Set-NetIPAddressViaSession.ps1 [-Session] <PSSession[]> [[-AdapterName] <string>] [-IPAddress] <string> [-PrefixLength] <byte> [-DefaultGateway] <string> [[-DnsAddresses] <string[]>] [[-NetworkCategory] <string>] [<CommonParameters>]
```

Sets IPv4 configuration for a Windows VM.

## Set-NetIPv6AddressViaSession

Script: [Set-NetIPv6AddressViaSession.ps1](Set-NetIPv6AddressViaSession.ps1)

```powershell
Set-NetIPv6AddressViaSession.ps1 [-Session] <PSSession[]> [[-AdapterName] <string>] [-IPAddress] <ipaddress> [-PrefixLength] <byte> [[-DnsAddresses] <string[]>] [<CommonParameters>]
```

Sets IPv6 configuration for a Windows VM.

## Get-VirtioImage

Script: [Get-VirtioImage.ps1](Get-VirtioImage.ps1)

```powershell
Get-VirtioImage.ps1 [[-OutputPath] <string>] [<CommonParameters>]
```

Downloads latest stable ISO image of [Windows VirtIO Drivers](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers).

Use `-OutputPath` parameter to set download location. If not informed, the current folder will be used.

Returns the path for downloaded file.

## Add-VirtioDrivers

Script: [Add-VirtioDrivers.ps1](Add-VirtioDrivers.ps1)

```powershell
Add-VirtioDrivers.ps1 [-VirtioIsoPath] <string> [-ImagePath] <string> [-Version] <string> [[-ImageIndex] <int>] [<CommonParameters>]
```

Adds [Windows VirtIO Drivers](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers) into a WIM or VHDX file.

You must inform the path of VirtIO ISO with `-VirtioIsoPath`. You can download the latest image from [here](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers#Using_the_ISO). Or just use [Get-VirtioImage.ps1](#get-virtioimage).

You must use `-ImagePath` to inform the path of file.

You may use `-Version` to specify the Windows version of the image (recommended). This ensures that all appropriate drivers for the system are installed correctly.

For WIM files you must also use `-ImageIndex` to inform the image index inside of WIM. For VHDX files the image index must be always `1` (the default).

Please note that -- unlike the `-AddVirtioDrivers` option from [New-VHDXFromWindowsImage.ps1](New-VHDXFromWindowsImage.ps1) -- this script cannot install the [QEMU Guest Agent](https://pve.proxmox.com/wiki/Qemu-guest-agent) in an existing `vhdx`, as its operations are limited to the offline image (cannot run the installer).

## New-WindowsUnattendFile

Script: [New-WindowsUnattendFile.ps1](New-WindowsUnattendFile.ps1)

```powershell
New-WindowsUnattendFile.ps1 [-AdministratorPassword] <string> [-Version] <string> [[-ComputerName] <string>] [[-FilePath] <string>] [[-Locale] <string>] [-AddVirtioDrivers] [<CommonParameters>]
```

Creates an unattended answer file tailored for the specified Windows `-Version` (supports Server 2016–2025, Windows 8.1–11). The administrator password is encrypted in the XML and written to `-FilePath` (defaults to `%TEMP%\unattend.xml`).

- `-ComputerName` lets you pre-set or use `*` (default) to randomize during setup.
- `-Locale` overrides the default `en-US` input/system/user locale entries.
- `-AddVirtioDrivers` appends a synchronous command to install VirtIO and QEMU Guest Agent MSI when the OS specializes.

## Enable-RemoteManagementViaSession

Script: [Enable-RemoteManagementViaSession.ps1](Enable-RemoteManagementViaSession.ps1)

```powershell
Enable-RemoteManagementViaSession.ps1 [-Session] <PSSession[]> [<CommonParameters>]
```

Enables Powershell Remoting, CredSSP server authentication and sets WinRM firewall rule to `Any` remote address (default: `LocalSubnet`).

# For Ubuntu VMs

## Get-UbuntuImage

Script: [Get-UbuntuImage.ps1](Get-UbuntuImage.ps1)

```powershell
Get-UbuntuImage.ps1 [[-OutputPath] <string>] [-Previous] [<CommonParameters>]
```

Downloads latest Ubuntu LTS cloud image and verify its integrity.

Use `-OutputPath` parameter to set download location. If not informed, the current folder will be used.

Use `-Previous` parameter to download the previous LTS image instead of the current LTS.

Returns the path for downloaded file.

## New-VMFromUbuntuImage (*)

Script: [New-VMFromUbuntuImage.ps1](New-VMFromUbuntuImage.ps1)

```powershell
New-VMFromUbuntuImage.ps1 -SourcePath <string> -VMName <string> -RootPassword <string> [-FQDN <string>] [-VHDXSizeBytes <uint64>] [-MemoryStartupBytes <long>] [-EnableDynamicMemory] [-ProcessorCount <long>] [-SwitchName <string>] [-MacAddress <string>] [-IPAddress <string>] [-Gateway <string>] [-DnsAddresses <string[]>] [-InterfaceName <string>] [-VlanId <string>] [-SecondarySwitchName <string>] [-SecondaryMacAddress <string>] [-SecondaryIPAddress <string>] [-SecondaryInterfaceName <string>] [-SecondaryVlanId <string>] [-InstallDocker] [<CommonParameters>]

New-VMFromUbuntuImage.ps1 -SourcePath <string> -VMName <string> -RootPublicKey <string> [-FQDN <string>] [-VHDXSizeBytes <uint64>] [-MemoryStartupBytes <long>] [-EnableDynamicMemory] [-ProcessorCount <long>] [-SwitchName <string>] [-MacAddress <string>] [-IPAddress <string>] [-Gateway <string>] [-DnsAddresses <string[]>] [-InterfaceName <string>] [-VlanId <string>] [-SecondarySwitchName <string>] [-SecondaryMacAddress <string>] [-SecondaryIPAddress <string>] [-SecondaryInterfaceName <string>] [-SecondaryVlanId <string>] [-InstallDocker] [<CommonParameters>]
```

Creates a Ubuntu VM from Ubuntu Cloud image.

You must have [qemu-img](https://github.com/fdcastel/qemu-img-windows-x64) installed. If you have [chocolatey](https://chocolatey.org/) you can install it with:

```powershell
choco install qemu-img -y
```

You can download Ubuntu cloud images from [here](https://cloud-images.ubuntu.com/releases/focal/release/) (get the `amd64.img` version). Or just use [Get-UbuntuImage.ps1](#get-ubuntuimage).

You must use `-RootPassword` to set a password or `-RootPublicKey` to set a public key for default `ubuntu` user.

You may configure network using `-VlanId`, `-IPAddress`, `-Gateway` and `-DnsAddresses` options. `-IPAddress` must be in `address/prefix` format. If not specified the network will be configured via DHCP.

You may rename interfaces with `-InterfaceName` and `-SecondaryInterfaceName`. This will set Hyper-V network adapter name and also set the interface name in Ubuntu.

You may add a second network using `-SecondarySwitchName`. You may configure it with `-Secondary*` options.

You may install Docker using `-InstallDocker` switch.

Returns the `VirtualMachine` created.

**(*) Requires administrative privileges**.

## Ubuntu: Example

```powershell
# Create a VM with static IP configuration and ssh public key access
$imgFile = .\Get-UbuntuImage.ps1 -Verbose
$vmName = 'TstUbuntu'
$fqdn = 'test.example.com'
$rootPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

.\New-VMFromUbuntuImage.ps1 `
    -SourcePath $imgFile `
    -VMName $vmName `
    -FQDN $fqdn `
    -RootPublicKey $rootPublicKey `
    -VHDXSizeBytes 60GB `
    -MemoryStartupBytes 2GB `
    -ProcessorCount 2 `
    -IPAddress 10.10.1.196/16 `
    -Gateway 10.10.1.250 `
    -DnsAddresses '8.8.8.8','8.8.4.4' `
    -Verbose

# Your public key is installed. This should not ask you for a password.
ssh ubuntu@10.10.1.196
```

# For Debian VMs

## Get-DebianImage

Script: [Get-DebianImage.ps1](Get-DebianImage.ps1)

```powershell
Get-DebianImage.ps1 [[-OutputPath] <string>] [-Previous] [<CommonParameters>]
```

Downloads latest Debian cloud image.

Use `-OutputPath` parameter to set download location. If not informed, the current folder will be used.

Use `-Previous` parameter to download the previous version instead of the current version.

Returns the path for downloaded file.

## New-VMFromDebianImage (*)

Script: [New-VMFromDebianImage.ps1](New-VMFromDebianImage.ps1)

```powershell
New-VMFromDebianImage.ps1 -SourcePath <string> -VMName <string> -RootPassword <string> [-FQDN <string>] [-VHDXSizeBytes <uint64>] [-MemoryStartupBytes <long>] [-EnableDynamicMemory] [-ProcessorCount <long>] [-SwitchName <string>] [-MacAddress <string>] [-IPAddress <string>] [-Gateway <string>] [-DnsAddresses <string[]>] [-InterfaceName <string>] [-VlanId <string>] [-SecondarySwitchName <string>] [-SecondaryMacAddress <string>] [-SecondaryIPAddress <string>] [-SecondaryInterfaceName <string>] [-SecondaryVlanId <string>] [-InstallDocker] [<CommonParameters>]

New-VMFromDebianImage.ps1 -SourcePath <string> -VMName <string> -RootPublicKey <string> [-FQDN <string>] [-VHDXSizeBytes <uint64>] [-MemoryStartupBytes <long>] [-EnableDynamicMemory] [-ProcessorCount <long>] [-SwitchName <string>] [-MacAddress <string>] [-IPAddress <string>] [-Gateway <string>] [-DnsAddresses <string[]>] [-InterfaceName <string>] [-VlanId <string>] [-SecondarySwitchName <string>] [-SecondaryMacAddress <string>] [-SecondaryIPAddress <string>] [-SecondaryInterfaceName <string>] [-SecondaryVlanId <string>] [-InstallDocker] [<CommonParameters>]
```

Creates a Debian VM from Debian Cloud image.

You must have [qemu-img](https://github.com/fdcastel/qemu-img-windows-x64) installed. If you have [chocolatey](https://chocolatey.org/) you can install it with:

```powershell
choco install qemu-img -y
```

You can download Debian cloud images from [here](https://cloud.debian.org/images/cloud/bullseye/daily) (get the `genericcloud-amd64 version`). Or just use [Get-DebianImage.ps1](#get-debianimage).

You must use `-RootPassword` to set a password or `-RootPublicKey` to set a public key for default `debian` user.

You may configure network using `-VlanId`, `-IPAddress`, `-Gateway` and `-DnsAddresses` options. `-IPAddress` must be in `address/prefix` format. If not specified the network will be configured via DHCP.

You may rename interfaces with `-InterfaceName` and `-SecondaryInterfaceName`. This will set Hyper-V network adapter name and also set the interface name in Debian.

You may add a second network using `-SecondarySwitchName`. You may configure it with `-Secondary*` options.

You may install Docker using `-InstallDocker` switch.

Returns the `VirtualMachine` created.

**(*) Requires administrative privileges**.

## Debian: Example

```powershell
# Create a VM with static IP configuration and ssh public key access
$imgFile = .\Get-DebianImage.ps1 -Verbose
$vmName = 'TstDebian'
$fqdn = 'test.example.com'
$rootPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

.\New-VMFromDebianImage.ps1 `
    -SourcePath $imgFile `
    -VMName $vmName `
    -FQDN $fqdn `
    -RootPublicKey $rootPublicKey `
    -VHDXSizeBytes 60GB `
    -MemoryStartupBytes 2GB `
    -ProcessorCount 2 `
    -IPAddress 10.10.1.197/16 `
    -Gateway 10.10.1.250 `
    -DnsAddresses '8.8.8.8','8.8.4.4' `
    -Verbose

# Your public key is installed. This should not ask you for a password.
ssh debian@10.10.1.197
```

# For images with no `cloud-init` support

## Get-OPNsenseImage

Script: [Get-OPNsenseImage.ps1](Get-OPNsenseImage.ps1)

```powershell
Get-OPNsenseImage.ps1 [[-OutputPath] <string>] [<CommonParameters>]
```

Downloads latest OPNsense ISO image.

Use `-OutputPath` parameter to set download location. If not informed, the current folder will be used.

Returns the path for downloaded file.

## New-VMFromIsoImage (*)

Script: [New-VMFromIsoImage.ps1](New-VMFromIsoImage.ps1)

```powershell
New-VMFromIsoImage.ps1 [-IsoPath] <string> [-VMName] <string> [[-VHDXSizeBytes] <uint64>] [[-MemoryStartupBytes] <long>] [[-ProcessorCount] <long>] [[-SwitchName] <string>] [[-MacAddress] <string>] [[-InterfaceName] <string>] [[-VlanId] <string>] [[-SecondarySwitchName] <string>] [[-SecondaryMacAddress] <string>] [[-SecondaryInterfaceName] <string>] [[-SecondaryVlanId] <string>] [-EnableDynamicMemory] [-EnableSecureBoot] [<CommonParameters>]
```

Creates a VM and boot it from a ISO image.

Returns the `VirtualMachine` created.

After installation, remember to remove the ISO mounted drive with:

```powershell
Get-VMDvdDrive -VMName 'vm-name' | Remove-VMDvdDrive
```

**(*) Requires administrative privileges**.

## OPNsense: Example

The following example will create a OPNsense router and a Windows VM in a private network which will have internet access through OPNsense.

It requires two Hyper-V Virtual Switches:

- `SWITCH` (type: External), connected to a network with internet access and DHCP; and
- `ISWITCH` (type: Internal), for the private netork.

From OPNsense convention, the first network interface will be assigned as LAN.
> **Note**: The default network address will be `192.168.1.1/24` with DHCP enabled.

```powershell
$isoFile = .\Get-OPNsenseImage.ps1 -Verbose
$vmName = 'TstOpnRouter'

.\New-VMFromIsoImage.ps1 `
    -IsoPath $isoFile `
    -VMName $vmName `
    -VHDXSizeBytes 60GB `
    -MemoryStartupBytes 2GB `
    -ProcessorCount 2 `
    -SwitchName 'ISWITCH' `
    -InterfaceName 'lan' `
    -SecondarySwitchName 'SWITCH' `
    -SecondaryInterfaceName 'wan' `
    -Verbose

# Windows Server 2022 image
$isoFile = 'C:\Adm\SW_DVD9_Win_Server_STD_CORE_2022__64Bit_English_DC_STD_MLF_X22-74290.ISO'
$vmName = 'TstOpnClient'
$pass = 'u531@rg3pa55w0rd$!'

.\New-VMFromWindowsImage.ps1 `
    -SourcePath $isoFile `
    -Edition 'Windows Server 2022 Standard (Desktop Experience)' `
    -VMName $vmName `
    -VHDXSizeBytes 60GB `
    -AdministratorPassword $pass `
    -Version 'Server2022Standard' `
    -MemoryStartupBytes 4GB `
    -VMProcessorCount 2 `
    -VMSwitchName 'ISWITCH'
```

The Windows VM should get an internal IP address (from `192.168.1.x/24` range) via DHCP from OPNsense and it should have working internet access.

Remember that OPNsense will be running in _live_ mode from ISO image. To install it logon via console with `installer` user and `opnsense` password.

After the installation, remove the installation media with:

```powershell
Get-VMDvdDrive -VMName 'TstOpnRouter' | Remove-VMDvdDrive
```

# Other commands

## Download-VerifiedFile

Script: [Download-VerifiedFile.ps1](Download-VerifiedFile.ps1)

```powershell
Download-VerifiedFile.ps1 [-Url] <string> [-ExpectedHash] <string> [[-TargetDirectory] <string>] [<CommonParameters>]
```

Downloads a file and validates its integrity through SHA256 hash verification.

If the file is already present and the hashes match, the download is skipped.

## Move-VMOffline

Script: [Move-VMOffline.ps1](Move-VMOffline.ps1)

```powershell
Move-VMOffline.ps1 [-VMName] <string> [-DestinationHost] <string> [-CertificateThumbprint] <string> [<CommonParameters>]
```

Uses Hyper-V replica to move a VM between hosts not joined in a domain.

# Helpers and tools

## Convert-WindowsImage

Script: [tools/Convert-WindowsImage.ps1](tools/Convert-WindowsImage.ps1)

```powershell
Convert-WindowsImage.ps1 -SourcePath <string> [-Edition <string[]>] [-VHDPath <string>] [-WorkingDirectory <string>] [-TempDirectory <string>] [-SizeBytes <ulong>] [-VHDFormat <VHD|VHDX|AUTO>] [-DiskLayout <BIOS|UEFI|WindowsToGo>] [-UnattendPath <string>] [-MergeFolder <string>] [-Driver <string[]>] [-Feature <string[]>] [-Package <string[]>] [-BCDBoot <string>] [-BCDinVHD <NativeBoot|VirtualMachine>] [-ExpandOnNativeBoot <bool>] [-RemoteDesktopEnable] [-Passthru] [-CacheSource] [-ShowUI] [-EnableDebugger <None|Serial|1394|USB|Network|Local> <debugger options>] [-DismPath <string>] [-ApplyEA]
```

Upstream Microsoft script to create bootable VHD/VHDX images from Windows ISOs or WIMs. Supports injecting unattend files, drivers, packages, features, debugger settings, and custom merge folders. Use `Get-Help ./tools/Convert-WindowsImage.ps1 -Detailed` for the exhaustive parameter set and debugger sub-parameters.

## Metadata-Functions

Script: [tools/Metadata-Functions.ps1](tools/Metadata-Functions.ps1)

Provides helpers for generating cloud-init metadata ISOs. Primary function:

- `New-MetadataIso -VMName <string> -Metadata <string> -UserData <string> [-NetworkConfig <string>]` — writes meta-data, user-data, and optional network-config into a temp folder and packages them into a CIDATA ISO.

## Virtio-Functions

Script: [tools/Virtio-Functions.ps1](tools/Virtio-Functions.ps1)

Helper functions to mount ISO images and inject VirtIO drivers into Windows images:

- `Get-VirtioDriverFolderName -Version <string>` — maps Windows versions to VirtIO driver subfolders.
- `Get-VirtioDrivers -VirtioDriveLetter <string> -Version <string>` — returns driver folders from a mounted VirtIO ISO; throws if media is invalid.
- `With-IsoImage -IsoFileName <string> -ScriptBlock <scriptblock>` — mounts an ISO, executes the scriptblock with drive letter, then dismounts.
- `With-WindowsImage -ImagePath <string> -ImageIndex <int> -VirtioDriveLetter <string> -ScriptBlock <scriptblock>` — mounts a Windows image index, runs the scriptblock with the mount path, then saves/dismounts.
