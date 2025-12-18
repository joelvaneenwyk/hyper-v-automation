function Set-NetIPAddressViaSession {
    <#
    .SYNOPSIS
        Sets IPv4 configuration for a Windows VM.
    
    .DESCRIPTION
        Configures static IPv4 address, gateway, and DNS settings for a Windows VM via PSSession.
    
    .PARAMETER Session
        The PSSession to the VM.
    
    .PARAMETER AdapterName
        The network adapter name. Default is 'Ethernet'.
    
    .PARAMETER IPAddress
        The static IP address to assign.
    
    .PARAMETER PrefixLength
        The subnet prefix length (e.g., 24 for /24).
    
    .PARAMETER DefaultGateway
        The default gateway IP address.
    
    .PARAMETER DnsAddresses
        Array of DNS server addresses. Default is Google DNS (8.8.8.8, 8.8.4.4).
    
    .PARAMETER NetworkCategory
        The network category (Public or Private). Default is Public.
    
    .EXAMPLE
        Set-NetIPAddressViaSession -Session $session -IPAddress "10.10.1.195" -PrefixLength 16 -DefaultGateway "10.10.1.250"
        Sets a static IP on the VM.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,

        [string]$AdapterName = 'Ethernet',

        [Parameter(Mandatory = $true)]
        [string]$IPAddress,

        [Parameter(Mandatory = $true)]
        [byte]$PrefixLength,
        
        [Parameter(Mandatory = $true)]
        [string]$DefaultGateway,
        
        [string[]]$DnsAddresses = @('8.8.8.8', '8.8.4.4'),

        [ValidateSet('Public', 'Private')]
        [string]$NetworkCategory = 'Public'
    )

    $ErrorActionPreference = 'Stop'

    Invoke-Command -Session $Session { 
        Remove-NetRoute -NextHop $using:DefaultGateway -Confirm:$false -ErrorAction SilentlyContinue
        $neta = Get-NetAdapter $using:AdapterName        # Use the exact adapter name for multi-adapter VMs
        $neta | Set-NetConnectionProfile -NetworkCategory $using:NetworkCategory
        $neta | Set-NetIPInterface -Dhcp Disabled
        $neta | Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false 

        # New-NetIPAddress may fail for certain scenarios (e.g. PrefixLength = 32). Using netsh instead.
        $mask = [IPAddress](([UInt32]::MaxValue) -shl (32 - $using:PrefixLength) -shr (32 - $using:PrefixLength))
        netsh interface ipv4 set address name="$($neta.InterfaceAlias)" static $using:IPAddress $mask.IPAddressToString $using:DefaultGateway

        $neta | Set-DnsClientServerAddress -Addresses $using:DnsAddresses
    } | Out-Null
}
