function Get-VirtioImage {
    <#
    .SYNOPSIS
        Downloads latest stable ISO image of Windows VirtIO Drivers.
    
    .DESCRIPTION
        Downloads the latest stable ISO image of Windows VirtIO Drivers from Fedora.
    
    .PARAMETER OutputPath
        The directory to download the file to. If not specified, uses the current directory.
    
    .OUTPUTS
        System.String
        Returns the path to the downloaded file.
    
    .EXAMPLE
        $virtioIso = Get-VirtioImage -OutputPath $env:TEMP
        Downloads the VirtIO ISO to the temp directory.
    #>
    [CmdletBinding()]
    param(
        [string]$OutputPath
    )

    $ErrorActionPreference = 'Stop'

    $urlRoot = 'https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/'
    $urlFile = 'virtio-win.iso'

    $url = "$urlRoot/$urlFile"
            
    if (-not $OutputPath) {
        $OutputPath = Get-Item '.\'
    }

    $imgFile = Join-Path $OutputPath $urlFile

    if ([System.IO.File]::Exists($imgFile)) {
        Write-Verbose "File '$imgFile' already exists. Nothing to do."
    }
    else {
        Write-Verbose "Downloading file '$imgFile'..."

        $client = New-Object System.Net.WebClient
        $client.DownloadFile($url, $imgFile)
    }

    $imgFile
}
