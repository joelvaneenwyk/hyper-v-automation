function Get-OPNsenseImage {
    <#
    .SYNOPSIS
        Downloads latest OPNsense ISO image.
    
    .DESCRIPTION
        Downloads the latest OPNsense ISO image and extracts it from the bz2 archive.
    
    .PARAMETER OutputPath
        The directory to download the file to. If not specified, uses the current directory.
    
    .OUTPUTS
        System.String
        Returns the path to the extracted ISO file.
    
    .EXAMPLE
        $isoFile = Get-OPNsenseImage -OutputPath $env:TEMP
        Downloads the latest OPNsense ISO.
    #>
    [CmdletBinding()]
    param(
        [string]$OutputPath
    )

    $ErrorActionPreference = 'Stop'

    $urlRoot = 'https://mirror.wdc1.us.leaseweb.net/opnsense/releases/25.7'
    $urlFile = 'OPNsense-25.7-dvd-amd64.iso.bz2'

    $url = "$urlRoot/$urlFile"
            
    if (-not $OutputPath) {
        $OutputPath = Get-Item '.\'
    }

    $isoFile = Join-Path $OutputPath $urlFile

    $uncompressedUrlFile = [System.IO.Path]::GetFileNameWithoutExtension($urlFile)
    $uncompressedIsoFile = Join-Path $OutputPath $uncompressedUrlFile

    if ([System.IO.File]::Exists($uncompressedIsoFile)) {
        Write-Verbose "File '$uncompressedIsoFile' already exists. Nothing to do."
    }
    else {
        if ([System.IO.File]::Exists($isoFile)) {
            Write-Verbose "File '$isoFile' already exists."
        }
        else {
            Write-Verbose "Downloading file '$isoFile'..."

            $client = New-Object System.Net.WebClient
            $client.DownloadFile($url, $isoFile)
        }

        $7zCommand = Get-Command "7z.exe" -ErrorAction SilentlyContinue
        if (-not $7zCommand) { 
            throw "7z.exe not found. Please install it with 'choco install 7zip -y'."
        }

        Write-Verbose "Extracting file '$isoFile' to '$OutputPath'..."
        & 7z.exe e $isoFile "-o$($OutputPath)" | Out-Null

        $fileExists = Test-Path -Path $uncompressedIsoFile
        if (-not $fileExists) {
            throw "Image '$uncompressedUrlFile' not found after extracting .bz2 file."
        }
    }

    $uncompressedIsoFile
}
