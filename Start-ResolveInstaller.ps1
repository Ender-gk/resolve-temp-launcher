#Requires -Version 5.1
# SPDX-License-Identifier: MIT
# Created by Ender-gk with development assistance from OpenAI Codex.
[CmdletBinding()]
param(
    [string]$InstallerPath,
    [string]$TempDirectory,
    [ValidateRange(1, 1000)][double]$MinimumFreeSpaceGB = 15,
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'ResolveTemp.Core.psm1') -Force
if (-not $CheckOnly) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this launcher from an administrator PowerShell, or right-click Start-ResolveInstaller.cmd and select Run as administrator.'
    }
}
if (-not $InstallerPath) {
    if ($CheckOnly) { throw '-CheckOnly requires -InstallerPath.' }
    Add-Type -AssemblyName System.Windows.Forms
    $picker = [Windows.Forms.OpenFileDialog]::new()
    try {
        $picker.Title = 'Select the original DaVinci Resolve Windows installer'
        $picker.Filter = 'Windows installer (*.exe)|*.exe'
        if ($picker.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { return }
        $InstallerPath = $picker.FileName
    } finally { $picker.Dispose() }
}
$verified = Test-ResolveInstallerSignature -InstallerPath $InstallerPath
$location = Get-ResolveTempLocation -Directory $TempDirectory -MinimumFreeSpaceGB $MinimumFreeSpaceGB
$payload = [IO.Path]::ChangeExtension($verified.Path, '.dat')
if ((Split-Path $verified.Path -Leaf) -like 'Install Resolve *' -and -not (Test-Path -LiteralPath $payload -PathType Leaf)) {
    throw 'The matching .dat payload is missing. Keep all original installer files together.'
}
Invoke-WithTemporaryDirectory -Directory $location.Path -Action {
    param($effectiveTemp)
    if ($CheckOnly) {
        [pscustomobject]@{
            Installer=$verified.Path;Signature='Valid';TempDirectory=$effectiveTemp
            FreeGB=$location.FreeGB;WriteTest='Passed';InstallerStarted=$false
        }
    } else {
        Write-Host "Temporary extraction directory: $effectiveTemp"
        $process = Start-Process -FilePath $verified.Path -WorkingDirectory (Split-Path $verified.Path -Parent) -Wait -PassThru
        Write-Host "Installer exited with code $($process.ExitCode)."
        if ($process.ExitCode -ne 0) { throw "Installer returned exit code $($process.ExitCode). Temporary settings have been restored." }
    }
}
