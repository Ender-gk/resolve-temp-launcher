#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'ResolveTemp.Core.psm1') -Force
$testRoot = Join-Path $root ('.test-work\path with spaces-' + [Guid]::NewGuid().ToString('N'))
$beforeTemp = [Environment]::GetEnvironmentVariable('TEMP', 'Process')
$beforeTmp = [Environment]::GetEnvironmentVariable('TMP', 'Process')
$passed = 0
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Restored {
    Assert-True ([Environment]::GetEnvironmentVariable('TEMP','Process') -ceq $beforeTemp) 'TEMP was not restored.'
    Assert-True ([Environment]::GetEnvironmentVariable('TMP','Process') -ceq $beforeTmp) 'TMP was not restored.'
}
try {
    $result = Invoke-WithTemporaryDirectory -Directory $testRoot -Action {
        param($directory)
        if ($env:TEMP -cne $directory -or $env:TMP -cne $directory) { throw 'Temporary variables not applied.' }
        'NORMAL_RETURN'
    }
    Assert-True ($result -eq 'NORMAL_RETURN') 'Action output changed.'
    Assert-Restored
    $passed++

    $caught = $false
    try { Invoke-WithTemporaryDirectory -Directory $testRoot -Action { throw 'EXPECTED_ACTION_FAILURE' } }
    catch { $caught = $_.Exception.Message -eq 'EXPECTED_ACTION_FAILURE' }
    Assert-True $caught 'Expected action failure was not propagated.'
    Assert-Restored
    $passed++

    $child = Invoke-WithTemporaryDirectory -Directory $testRoot -Action {
        & (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -NoProfile -Command '$env:TEMP; $env:TMP'
    }
    Assert-True (@($child).Count -eq 2 -and $child[0] -ieq $testRoot -and $child[1] -ieq $testRoot) 'Child process did not inherit TEMP/TMP.'
    Assert-Restored
    $passed++

    $caught = $false
    try { Get-ResolveTempLocation -Directory '.\relative-path' }
    catch { $caught = $true }
    Assert-True $caught 'Relative path was accepted.'
    $passed++

    $fake = Join-Path $testRoot 'not-an-installer.exe'
    [IO.File]::WriteAllText($fake, 'Unsigned test fixture; not executable code.')
    $caught = $false
    try { Test-ResolveInstallerSignature -InstallerPath $fake }
    catch { $caught = $true }
    Assert-True $caught 'Unsigned installer was accepted.'
    $passed++
    Write-Host "PASS: $passed smoke tests. No installer was started."
} finally {
    Assert-Restored
    # Delete only files created by these tests, never recurse over a computed path.
    if (Test-Path -LiteralPath $testRoot) {
        Get-ChildItem -LiteralPath $testRoot -File | ForEach-Object { [IO.File]::Delete($_.FullName) }
        [IO.Directory]::Delete($testRoot, $false)
    }
}
