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
