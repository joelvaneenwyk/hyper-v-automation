# Fix PSScriptAnalyzer Findings Across Repository PowerShell Scripts

> Issue: TBD

## Description

Running `pwsh -NoProfile -F ./tools/lint.ps1` fails due to **PSScriptAnalyzer** reporting **1 error** and **161 warnings** across repo scripts and settings. We should address the security-related error first (blocks lint), then systematically reduce warnings (prioritize security + correctness, then style).

## Why This Matters

• **CI/Lint is currently red** due to a blocking analyzer error
• Several findings relate to **credential handling** and **unsafe patterns**
• Many warnings are **mechanical fixes** we can auto-format or batch-edit

## Repro

```log
pwsh -NoProfile -F ./tools/lint.ps1
```

## Current Result

• Errors — 1
• Warnings — 161
• Lint exits non-zero — repo task fails

## Blocking Error

### ❌ PSAvoidUsingConvertToSecureStringWithPlainText

• **File** `New-VMSession.ps1`
• **Line** 18
• **Issue** `ConvertTo-SecureString` used with plaintext, which can expose sensitive data
• **Goal** Replace plaintext-to-secure conversions with safer patterns (SecureString/PSCredential inputs, or secure retrieval mechanisms)

## High Priority Warnings

### Credential Handling

• `PSAvoidUsingPlainTextForPassword`
⤷ `New-VHDXFromWindowsImage.ps1:18` — `$AdministratorPassword` should be `SecureString` or `PSCredential`
⤷ `New-VMFromDebianImage.ps1:21` — `$RootPassword` should be `SecureString` or `PSCredential`
⤷ `New-VMFromUbuntuImage.ps1:21` — `$RootPassword` should be `SecureString` or `PSCredential`
⤷ `New-VMFromWindowsImage.ps1:17` — `$AdministratorPassword` should be `SecureString` or `PSCredential`
⤷ `New-VMSession.ps1:6` — `$AdministratorPassword` should be `SecureString` or `PSCredential`
⤷ `New-WindowsUnattendFile.ps1:3` — `$AdministratorPassword` should be `SecureString` or `PSCredential`

### Command Safety and Modernization

• `PSAvoidUsingInvokeExpression`
⤷ `Convert-WindowsImage.ps1:1150`, `Convert-WindowsImage.ps1:1601` — remove `Invoke-Expression` and use safer invocation patterns

• `PSAvoidUsingWMICmdlet`
⤷ `New-VMFromDebianImage.ps1:109`
⤷ `New-VMFromIsoImage.ps1:49`, `New-VMFromIsoImage.ps1:50`
⤷ `New-VMFromUbuntuImage.ps1:109`
⤷ `New-VMFromWindowsImage.ps1:53`, `New-VMFromWindowsImage.ps1:54`
⤷ `Convert-WindowsImage.ps1:730`
⤷ Replace WMI cmdlets with CIM equivalents where feasible

### Output and Logging Hygiene

• `PSAvoidUsingWriteHost`
⤷ `Convert-WindowsImage.ps1` multiple lines
⤷ `docs.ps1` many lines
⤷ `format.ps1` several lines
⤷ `lint.ps1` several lines
⤷ `test.ps1` many lines
⤷ Prefer `Write-Verbose`, `Write-Information`, `Write-Output` based on intent

### Encoding

• `PSUseBOMForUnicodeEncodedFile`
⤷ `docs.ps1`, `format.ps1`, `lint.ps1`, `test.ps1`
⤷ Ensure consistent UTF encoding policy across scripts

## Quality and Style Warnings To Batch Fix

• `PSUseConsistentWhitespace`
⤷ Multiple lines in `New-VHDXFromWindowsImage.ps1` and `PSScriptAnalyzerSettings.psd1`
⤷ Likely solvable via formatter + minimal hand edits

• `PSUseDeclaredVarsMoreThanAssignments`
⤷ `New-VMFromIsoImage.ps1` — `vmms`, `metadataIso` unused
⤷ `New-VMFromWindowsImage.ps1` — `vmms` unused
⤷ `General.Tests.ps1` — `repoRoot` unused
⤷ `Convert-WindowsImage.ps1` — multiple unused constants/vars
⤷ Remove or use variables intentionally

• `PSUseApprovedVerbs`
⤷ `Normalize-MacAddress` used in multiple scripts
⤷ `Run-Executable` in `Convert-WindowsImage.ps1`
⤷ `With-IsoImage`, `With-WindowsImage` in `Virtio-Functions.ps1`
⤷ Rename functions to approved verb equivalents, or suppress with justification if public API compatibility matters

• `PSUseSingularNouns`
⤷ `Add-WindowsImageTypes` and `Get-VirtioDrivers`
⤷ Rename or suppress with rationale

• `PSUseProcessBlockForPipelineCommand`
⤷ Several commands in `Convert-WindowsImage.ps1` accept pipeline input but lack `process {}`
⤷ Add `begin/process/end` blocks as appropriate

• `PSPossibleIncorrectComparisonWithNull`
⤷ `Convert-WindowsImage.ps1:2234`, `2240`, `2258`
⤷ Ensure `$null` is on the left side of equality comparisons

• `PSAvoidDefaultValueSwitchParameter`
⤷ `Convert-WindowsImage.ps1:277` — switch defaults to true
⤷ Refactor to non-switch parameter or invert logic

• `PSAvoidGlobalVars`
⤷ `Convert-WindowsImage.ps1:673`, `698` — `global:mountedHive`
⤷ Refactor to script/module scope or pass state explicitly

• `PSUseShouldProcessForStateChangingFunctions`
⤷ `Metadata-Functions.ps1:5` — `New-MetadataIso` should support `ShouldProcess`
⤷ Add `[CmdletBinding(SupportsShouldProcess=$true)]` and gate side effects with `$PSCmdlet.ShouldProcess(...)`

## Acceptance Criteria

• Lint task succeeds — **0 errors** from PSScriptAnalyzer
• High-risk security items addressed — no plaintext password usage, no plaintext SecureString conversion, no `Invoke-Expression`
• Warning count substantially reduced or justified with scoped suppressions and comments
• Formatting/encoding consistent across scripts

## Implementation Notes

• Triage order suggestion
⤷ Fix the single **blocking error** first
⤷ Then fix **credential-related warnings** (same refactor pattern across scripts)
⤷ Then eliminate **Invoke-Expression**, **Write-Host**, **WMI → CIM**
⤷ Finally batch-fix style and unused vars

## Log

```pwsh
task: [default] pwsh -NoProfile -F ./tools/lint.ps1
Running PSScriptAnalyzer...
Repository: E:\source\github.com\joelvaneenwyk\hyper-v-automation
Settings: E:\source\github.com\joelvaneenwyk\hyper-v-automation\PSScriptAnalyzerSettings.psd1

Analysis Results:
  Errors: 1
  Warnings: 161
  Information: 0

ERRORS:
  ❌ New-VMSession.ps1:18
     [PSAvoidUsingConvertToSecureStringWithPlainText] File 'New-VMSession.ps1' uses ConvertTo-SecureString with plaintext. This will expose secure information. Encrypted standard strings should be used instead.

WARNINGS:
  ⚠️  New-VHDXFromWindowsImage.ps1:18
     [PSAvoidUsingPlainTextForPassword] Parameter '$AdministratorPassword' should not use String type but either SecureString or PSCredential, otherwise it increases the chance to expose this sensitive information.

  ⚠️  New-VHDXFromWindowsImage.ps1:76
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  New-VHDXFromWindowsImage.ps1:77
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  New-VHDXFromWindowsImage.ps1:78
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  New-VHDXFromWindowsImage.ps1:79
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  New-VHDXFromWindowsImage.ps1:80
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  New-VHDXFromWindowsImage.ps1:81
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  New-VHDXFromWindowsImage.ps1:83
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  New-VMFromDebianImage.ps1:21
     [PSAvoidUsingPlainTextForPassword] Parameter '$RootPassword' should not use String type but either SecureString or PSCredential, otherwise it increases the chance to expose this sensitive information.

  ⚠️  New-VMFromDebianImage.ps1:109
     [PSAvoidUsingWMICmdlet] File 'New-VMFromDebianImage.ps1' uses WMI cmdlet. For PowerShell 3.0 and above, use CIM cmdlet which perform the same tasks as the WMI cmdlets. The CIM cmdlets comply with WS-Management (WSMan) standards and with the Common Information Model (CIM) standard, which enables the cmdlets to use the same techniques to manage Windows computers and those running other operating systems.

  ⚠️  New-VMFromDebianImage.ps1:100
     [PSUseApprovedVerbs] The cmdlet 'Normalize-MacAddress' uses an unapproved verb.

  ⚠️  New-VMFromIsoImage.ps1:49
     [PSAvoidUsingWMICmdlet] File 'New-VMFromIsoImage.ps1' uses WMI cmdlet. For PowerShell 3.0 and above, use CIM cmdlet which perform the same tasks as the WMI cmdlets. The CIM cmdlets comply with WS-Management (WSMan) standards and with the Common Information Model (CIM) standard, which enables the cmdlets to use the same techniques to manage Windows computers and those running other operating systems.

  ⚠️  New-VMFromIsoImage.ps1:50
     [PSAvoidUsingWMICmdlet] File 'New-VMFromIsoImage.ps1' uses WMI cmdlet. For PowerShell 3.0 and above, use CIM cmdlet which perform the same tasks as the WMI cmdlets. The CIM cmdlets comply with WS-Management (WSMan) standards and with the Common Information Model (CIM) standard, which enables the cmdlets to use the same techniques to manage Windows computers and those running other operating systems.

  ⚠️  New-VMFromIsoImage.ps1:40
     [PSUseApprovedVerbs] The cmdlet 'Normalize-MacAddress' uses an unapproved verb.

  ⚠️  New-VMFromIsoImage.ps1:49
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'vmms' is assigned but never used.

  ⚠️  New-VMFromIsoImage.ps1:52
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'metadataIso' is assigned but never used.

  ⚠️  New-VMFromUbuntuImage.ps1:21
     [PSAvoidUsingPlainTextForPassword] Parameter '$RootPassword' should not use String type but either SecureString or PSCredential, otherwise it increases the chance to expose this sensitive information.

  ⚠️  New-VMFromUbuntuImage.ps1:100
     [PSUseApprovedVerbs] The cmdlet 'Normalize-MacAddress' uses an unapproved verb.

  ⚠️  New-VMFromUbuntuImage.ps1:109
     [PSAvoidUsingWMICmdlet] File 'New-VMFromUbuntuImage.ps1' uses WMI cmdlet. For PowerShell 3.0 and above, use CIM cmdlet which perform the same tasks as the WMI cmdlets. The CIM cmdlets comply with WS-Management (WSMan) standards and with the Common Information Model (CIM) standard, which enables the cmdlets to use the same techniques to manage Windows computers and those running other operating systems.

  ⚠️  New-VMFromWindowsImage.ps1:17
     [PSAvoidUsingPlainTextForPassword] Parameter '$AdministratorPassword' should not use String type but either SecureString or PSCredential, otherwise it increases the chance to expose this sensitive information.

  ⚠️  New-VMFromWindowsImage.ps1:53
     [PSAvoidUsingWMICmdlet] File 'New-VMFromWindowsImage.ps1' uses WMI cmdlet. For PowerShell 3.0 and above, use CIM cmdlet which perform the same tasks as the WMI cmdlets. The CIM cmdlets comply with WS-Management (WSMan) standards and with the Common Information Model (CIM) standard, which enables the cmdlets to use the same techniques to manage Windows computers and those running other operating systems.

  ⚠️  New-VMFromWindowsImage.ps1:54
     [PSAvoidUsingWMICmdlet] File 'New-VMFromWindowsImage.ps1' uses WMI cmdlet. For PowerShell 3.0 and above, use CIM cmdlet which perform the same tasks as the WMI cmdlets. The CIM cmdlets comply with WS-Management (WSMan) standards and with the Common Information Model (CIM) standard, which enables the cmdlets to use the same techniques to manage Windows computers and those running other operating systems.

  ⚠️  New-VMFromWindowsImage.ps1:53
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'vmms' is assigned but never used.

  ⚠️  New-VMSession.ps1:6
     [PSAvoidUsingPlainTextForPassword] Parameter '$AdministratorPassword' should not use String type but either SecureString or PSCredential, otherwise it increases the chance to expose this sensitive information.

  ⚠️  New-WindowsUnattendFile.ps1:3
     [PSAvoidUsingPlainTextForPassword] Parameter '$AdministratorPassword' should not use String type but either SecureString or PSCredential, otherwise it increases the chance to expose this sensitive information.

  ⚠️  PSScriptAnalyzerSettings.psd1:3
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:9
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:19
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:20
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:21
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:22
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:23
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:27
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:28
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:29
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:31
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:35
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:36
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:37
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:41
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:42
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:43
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:44
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:45
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:46
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:47
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:49
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:50
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:54
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:58
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:62
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:66
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:67
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:68
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:69
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  PSScriptAnalyzerSettings.psd1:71
     [PSUseConsistentWhitespace] Use space before and after binary and assignment operators.

  ⚠️  General.Tests.ps1:12
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'repoRoot' is assigned but never used.

  ⚠️  Convert-WindowsImage.ps1:277
     [PSAvoidDefaultValueSwitchParameter] File 'Convert-WindowsImage.ps1' has a switch parameter default to true.

  ⚠️  Convert-WindowsImage.ps1:673
     [PSAvoidGlobalVars] Found global variable 'global:mountedHive'.

  ⚠️  Convert-WindowsImage.ps1:698
     [PSAvoidGlobalVars] Found global variable 'global:mountedHive'.

  ⚠️  Convert-WindowsImage.ps1:756
     [PSAvoidUsingWriteHost] File 'Convert-WindowsImage.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  Convert-WindowsImage.ps1:786
     [PSAvoidUsingWriteHost] File 'Convert-WindowsImage.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  Convert-WindowsImage.ps1:801
     [PSAvoidUsingWriteHost] File 'Convert-WindowsImage.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  Convert-WindowsImage.ps1:902
     [PSAvoidUsingWriteHost] File 'Convert-WindowsImage.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  Convert-WindowsImage.ps1:730
     [PSAvoidUsingWMICmdlet] File 'Convert-WindowsImage.ps1' uses WMI cmdlet. For PowerShell 3.0 and above, use CIM cmdlet which perform the same tasks as the WMI cmdlets. The CIM cmdlets comply with WS-Management (WSMan) standards and with the Common Information Model (CIM) standard, which enables the cmdlets to use the same techniques to manage Windows computers and those running other operating systems.

  ⚠️  Convert-WindowsImage.ps1:1150
     [PSAvoidUsingInvokeExpression] Invoke-Expression is used. Please remove Invoke-Expression from script and find other options instead.

  ⚠️  Convert-WindowsImage.ps1:1601
     [PSAvoidUsingInvokeExpression] Invoke-Expression is used. Please remove Invoke-Expression from script and find other options instead.

  ⚠️  Convert-WindowsImage.ps1:807
     [PSUseApprovedVerbs] The cmdlet 'Run-Executable' uses an unapproved verb.

  ⚠️  Convert-WindowsImage.ps1:647
     [PSUseProcessBlockForPipelineCommand] Command accepts pipeline input but has not defined a process block.

  ⚠️  Convert-WindowsImage.ps1:686
     [PSUseProcessBlockForPipelineCommand] Command accepts pipeline input but has not defined a process block.

  ⚠️  Convert-WindowsImage.ps1:754
     [PSUseProcessBlockForPipelineCommand] Command accepts pipeline input but has not defined a process block.

  ⚠️  Convert-WindowsImage.ps1:769
     [PSUseProcessBlockForPipelineCommand] Command accepts pipeline input but has not defined a process block.

  ⚠️  Convert-WindowsImage.ps1:784
     [PSUseProcessBlockForPipelineCommand] Command accepts pipeline input but has not defined a process block.

  ⚠️  Convert-WindowsImage.ps1:799
     [PSUseProcessBlockForPipelineCommand] Command accepts pipeline input but has not defined a process block.

  ⚠️  Convert-WindowsImage.ps1:878
     [PSUseProcessBlockForPipelineCommand] Command accepts pipeline input but has not defined a process block.

  ⚠️  Convert-WindowsImage.ps1:2288
     [PSUseSingularNouns] The cmdlet 'Add-WindowsImageTypes' uses a plural noun. A singular noun should be used instead.

  ⚠️  Convert-WindowsImage.ps1:2234
     [PSPossibleIncorrectComparisonWithNull] $null should be on the left side of equality comparisons.

  ⚠️  Convert-WindowsImage.ps1:2240
     [PSPossibleIncorrectComparisonWithNull] $null should be on the left side of equality comparisons.

  ⚠️  Convert-WindowsImage.ps1:2258
     [PSPossibleIncorrectComparisonWithNull] $null should be on the left side of equality comparisons.

  ⚠️  Convert-WindowsImage.ps1:577
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'PARTITION_STYLE_MBR' is assigned but never used.

  ⚠️  Convert-WindowsImage.ps1:578
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'PARTITION_STYLE_GPT' is assigned but never used.

  ⚠️  Convert-WindowsImage.ps1:598
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'vhdxMaxSize' is assigned but never used.

  ⚠️  Convert-WindowsImage.ps1:1872
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'reservedPartition' is assigned but never used.

  ⚠️  Convert-WindowsImage.ps1:1021
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'txtWorkingDirectory' is assigned but never used.

  ⚠️  Convert-WindowsImage.ps1:1039
     [PSUseDeclaredVarsMoreThanAssignments] The variable 'UnattendPath' is assigned but never used.

  ⚠️  docs.ps1:35
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:47
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:48
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:49
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:60
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:75
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:84
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:95
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:101
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:106
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:111
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:112
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:113
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:114
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:115
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:116
     [PSAvoidUsingWriteHost] File 'docs.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  docs.ps1:
     [PSUseBOMForUnicodeEncodedFile] Missing BOM encoding for non-ASCII encoded file 'docs.ps1'

  ⚠️  format.ps1:37
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:53
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:72
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:75
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:89
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:92
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:97
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:99
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:101
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:102
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:106
     [PSAvoidUsingWriteHost] File 'format.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  format.ps1:
     [PSUseBOMForUnicodeEncodedFile] Missing BOM encoding for non-ASCII encoded file 'format.ps1'

  ⚠️  lint.ps1:36
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:48
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:49
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:50
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:51
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:62
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:63
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:64
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:65
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:66
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:70
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:72
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:73
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:74
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:80
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:82
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:83
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:84
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:90
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:92
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:93
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:94
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:102
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:106
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:110
     [PSAvoidUsingWriteHost] File 'lint.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  lint.ps1:
     [PSUseBOMForUnicodeEncodedFile] Missing BOM encoding for non-ASCII encoded file 'lint.ps1'

  ⚠️  Metadata-Functions.ps1:5
     [PSUseShouldProcessForStateChangingFunctions] Function 'New-MetadataIso' has verb that could change system state. Therefore, the function has to support 'ShouldProcess'.

  ⚠️  test.ps1:55
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:89
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:90
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:91
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:96
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:97
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:98
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:99
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:100
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:101
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:102
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:103
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:108
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:111
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:118
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:122
     [PSAvoidUsingWriteHost] File 'test.ps1' uses Write-Host. Avoid using Write-Host because it might not work in all hosts, does not work when there is no host, and (prior to PS 5.0) cannot be suppressed, captured, or redirected. Instead, use Write-Output, Write-Verbose, or Write-Information.

  ⚠️  test.ps1:
     [PSUseBOMForUnicodeEncodedFile] Missing BOM encoding for non-ASCII encoded file 'test.ps1'

  ⚠️  Virtio-Functions.ps1:62
     [PSUseApprovedVerbs] The cmdlet 'With-IsoImage' uses an unapproved verb.

  ⚠️  Virtio-Functions.ps1:77
     [PSUseApprovedVerbs] The cmdlet 'With-WindowsImage' uses an unapproved verb.

  ⚠️  Virtio-Functions.ps1:42
     [PSUseSingularNouns] The cmdlet 'Get-VirtioDrivers' uses a plural noun. A singular noun should be used instead.

❌ Analysis failed with 1 error(s)
task: Failed to run task "default": exit status 1
```
