function Enable-RemoteManagementViaSession {
    <#
    .SYNOPSIS
        Enables PowerShell Remoting and CredSSP server authentication.
    
    .DESCRIPTION
        Enables PowerShell Remoting, CredSSP server authentication and sets WinRM firewall rule
        to 'Any' remote address (default: 'LocalSubnet').
    
    .PARAMETER Session
        The PSSession to the VM.
    
    .EXAMPLE
        Enable-RemoteManagementViaSession -Session $session
        Enables remote management on the VM.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session
    )

    $ErrorActionPreference = 'Stop'

    Invoke-Command -Session $Session { 
        # Enable remote administration
        Enable-PSRemoting -SkipNetworkProfileCheck -Force
        Enable-WSManCredSSP -Role server -Force

        # Default rule is for 'Local Subnet' only. Change to 'Any'.
        Set-NetFirewallRule -DisplayName 'Windows Remote Management (HTTP-In)' -RemoteAddress Any
    } | Out-Null
}
