function New-VMSession {
    <#
    .SYNOPSIS
        Creates a new PSSession into a VM.
    
    .DESCRIPTION
        Creates a new PSSession into a VM. In case of error, keeps retrying until connected.
        Useful for waiting until a VM is ready to accept commands.
    
    .PARAMETER VMName
        The name of the virtual machine.
    
    .PARAMETER AdministratorPassword
        The administrator password for the VM.
    
    .PARAMETER DomainName
        Optional domain name for the administrator account.
    
    .OUTPUTS
        System.Management.Automation.Runspaces.PSSession
        Returns the PSSession created.
    
    .EXAMPLE
        $session = New-VMSession -VMName "MyVM" -AdministratorPassword $password
        Creates a new session to MyVM.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VMName,

        [Parameter(Mandatory = $true)]
        [SecureString]$AdministratorPassword,

        [string]$DomainName
    )

    if ($DomainName) {
        $userName = "$DomainName\administrator"
    }
    else {
        $userName = 'administrator'
    }
    $cred = New-Object System.Management.Automation.PSCredential($userName, $AdministratorPassword)

    do {
        $result = New-PSSession -VMName $VMName -Credential $cred -ErrorAction SilentlyContinue

        if (-not $result) {
            Write-Verbose "Waiting for connection with '$VMName'..."
            Start-Sleep -Seconds 1
        }
    } while (-not $result)
    $result
}
