# Enables TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$url = 'https://codeload.github.com/joelvaneenwyk/hyper-v-automation/zip/main'
$fileName = Join-Path $env:TEMP 'hyper-v-automation-main.zip'

Invoke-RestMethod $url -OutFile $fileName
Expand-Archive $fileName -DestinationPath $env:TEMP -Force

Set-Location "$env:TEMP\hyper-v-automation-main"
