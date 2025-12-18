function Download-VerifiedFile {
    <#
    .SYNOPSIS
        Downloads a file and validates its integrity through SHA256 hash verification.
    
    .DESCRIPTION
        Downloads a file to a target directory and verifies its SHA256 hash. If the file exists
        and the hash matches, the download is skipped. If the hash doesn't match, the file is
        re-downloaded.
    
    .PARAMETER Url
        The URL to download the file from.
    
    .PARAMETER ExpectedHash
        The expected SHA256 hash of the file.
    
    .PARAMETER TargetDirectory
        The directory to save the file to. Default is $env:TEMP.
    
    .OUTPUTS
        System.String
        Returns the path to the downloaded file.
    
    .EXAMPLE
        $file = Download-VerifiedFile -Url "https://example.com/file.zip" -ExpectedHash "abc123..."
        Downloads and verifies the file.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$ExpectedHash,
        
        [Parameter(Mandatory = $false)]
        [string]$TargetDirectory = $env:TEMP
    )

    # Ensure target directory exists
    if (-not (Test-Path -Path $TargetDirectory -PathType Container)) {
        New-Item -Path $TargetDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "Created directory: $TargetDirectory"
    }

    # Extract filename from URL
    $fileName = [System.IO.Path]::GetFileName($Url)
    $filePath = Join-Path -Path $TargetDirectory -ChildPath $fileName

    # Flag to determine if download is needed
    $downloadRequired = $true

    # Check if file already exists
    if (Test-Path -Path $filePath -PathType Leaf) {
        Write-Verbose "File already exists: $filePath. Verifying hash..."
        
        # Calculate hash of existing file
        $fileHash = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
        
        # Compare hash
        if ($fileHash -eq $ExpectedHash) {
            Write-Verbose "Hash verification successful for existing file."
            $downloadRequired = $false
        }
        else {
            Write-Warning "Existing file hash does not match expected hash. Re-downloading..."
        }
    }

    # Download file if required
    if ($downloadRequired) {
        try {
            Write-Verbose "Downloading $Url to $filePath..."
            Invoke-WebRequest -Uri $Url -OutFile $filePath -UseBasicParsing
            
            # Verify hash of downloaded file
            $fileHash = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
            
            if ($fileHash -ne $ExpectedHash) {
                Remove-Item -Path $filePath -Force
                throw "Downloaded file hash ($fileHash) does not match expected hash ($ExpectedHash)."
            }
            
            Write-Verbose "Download complete and hash verification successful."
        }
        catch {
            throw "Failed to download or verify file: $_"
        }
    }

    # Return the file path
    return $filePath
}
