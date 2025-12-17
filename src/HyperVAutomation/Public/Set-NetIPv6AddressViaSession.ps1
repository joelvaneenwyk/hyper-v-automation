function Set-NetIPv6AddressViaSession {
    <#
    .SYNOPSIS
        Sets IPv6 configuration for a Windows VM.
    
    .DESCRIPTION
        Configures static IPv6 address and DNS settings for a Windows VM via PSSession.
    
    .PARAMETER Session
        The PSSession to the VM.
    
    .PARAMETER AdapterName
        The network adapter name. If not specified, uses the adapter with an IPv4 default gateway.
    
    .PARAMETER IPAddress
        The static IPv6 address to assign.
    
    .PARAMETER PrefixLength
        The subnet prefix length (e.g., 64 for /64).
    
    .PARAMETER DnsAddresses
        Array of DNS server addresses. Default is Google IPv6 DNS.
    
    .EXAMPLE
        Set-NetIPv6AddressViaSession -Session $session -IPAddress "2001:db8::1" -PrefixLength 64
        Sets a static IPv6 address on the VM.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,

        [string]$AdapterName,

        [ValidateScript({
                if ($_.AddressFamily -ne 'InterNetworkV6') {
                    throw 'IPAddress must be an IPv6 address.'
                }
                $true
            })]
        [Parameter(Mandatory = $true)]
        [ipaddress]$IPAddress,

        [Parameter(Mandatory = $true)]
        [byte]$PrefixLength,
        
        [string[]]$DnsAddresses = @('2001:4860:4860::8888', '2001:4860:4860::8844')
    )

    $ErrorActionPreference = 'Stop'

    Invoke-Command -Session $Session { 
        $ifName = $using:AdapterName

        if (-not $ifName) {
            # Get the gateway interface for IPv4
            $ifName = (Get-NetIPConfiguration | ForEach-Object IPv4DefaultGateway).InterfaceAlias
        }

        $neta = Get-NetAdapter -Name $ifName
        $neta | Get-NetIPAddress -AddressFamily IPv6 -PrefixOrigin Manual -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false 
        $neta | New-NetIPAddress -AddressFamily IPv6 -IPAddress $using:IPAddress -PrefixLength $using:PrefixLength

        $neta | Set-DnsClientServerAddress -Addresses $using:DnsAddresses
    } | Out-Null
}
