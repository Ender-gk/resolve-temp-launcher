# SPDX-License-Identifier: MIT
# Created by Ender-gk with development assistance from OpenAI Codex.
Set-StrictMode -Version Latest

function Get-ResolveTempLocation {
    [CmdletBinding()]
    param([string]$Directory, [double]$MinimumFreeSpaceGB = 15)
    if (-not $Directory) {
        $drives = @([IO.DriveInfo]::GetDrives() | Where-Object {
            $_.IsReady -and $_.DriveType -eq 'Fixed' -and $_.Name -ine ($env:SystemDrive + '\')
        } | Sort-Object AvailableFreeSpace -Descending)
        $preferred = @($drives | Where-Object Name -eq 'D:\')
        if ($preferred.Count -and $preferred[0].AvailableFreeSpace -ge ($MinimumFreeSpaceGB * 1GB)) {
            $drive = $preferred[0]
        } elseif ($drives.Count) { $drive = $drives[0] }
        else { throw 'No secondary local drive is available. Specify -TempDirectory.' }
        $Directory = Join-Path $drive.Name 'ResolveInstallerTemp'
    }
    if ($Directory -notmatch '^[A-Za-z]:\\') { throw 'Specify an absolute local path, for example D:\ResolveInstallerTemp.' }
    $full = [IO.Path]::GetFullPath($Directory).TrimEnd('\')
    $root = [IO.Path]::GetPathRoot($full)
    if ($root -ieq ($env:SystemDrive + '\')) { throw 'Choose a drive other than the Windows system drive.' }
    if ($full -ieq $root.TrimEnd('\')) { throw 'Use a subdirectory rather than a drive root.' }
    $drive = [IO.DriveInfo]::new($root)
    if (-not $drive.IsReady -or $drive.DriveType -ne 'Fixed') { throw 'Choose an available local fixed drive.' }
    if ($drive.AvailableFreeSpace -lt ($MinimumFreeSpaceGB * 1GB)) {
        throw ('Not enough free space: {0:N2} GB available; {1:N2} GB required.' -f ($drive.AvailableFreeSpace / 1GB), $MinimumFreeSpaceGB)
    }
    [pscustomobject]@{Path=$full;FreeGB=[math]::Round($drive.AvailableFreeSpace / 1GB, 2)}
}

function Test-ResolveInstallerSignature {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InstallerPath)
    $item = Get-Item -LiteralPath $InstallerPath -ErrorAction Stop
    if ($item.PSIsContainer -or $item.Extension -ine '.exe') { throw 'Select the original Windows EXE installer.' }
    $signature = Get-AuthenticodeSignature -LiteralPath $item.FullName
    if ($signature.Status -ne 'Valid' -or $null -eq $signature.SignerCertificate -or
        $signature.SignerCertificate.Subject -notmatch '(?i)(?:^|,)\s*(?:CN|O)=Blackmagic Design(?:[ ,.]|$)') {
        throw 'The installer must have a valid Blackmagic Design Authenticode signature. No program was started.'
    }
    [pscustomobject]@{Path=$item.FullName;Signer=$signature.SignerCertificate.Subject}
}

function Invoke-WithTemporaryDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][scriptblock]$Action
    )
    if ($Directory -notmatch '^[A-Za-z]:\\') { throw 'The temporary directory must be an absolute local path.' }
    $full = [IO.Path]::GetFullPath($Directory).TrimEnd('\')
    $cursor = $full
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force -ErrorAction Stop
            if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw "The temporary path contains a file or redirected directory: $cursor"
            }
        }
        $parent = [IO.Path]::GetDirectoryName($cursor.TrimEnd('\'))
        if (-not $parent -or $parent -eq $cursor) { break }
        $cursor = $parent
    }
    New-Item -ItemType Directory -Path $full -Force -ErrorAction Stop | Out-Null
    $probe = Join-Path $full ('resolve_temp_probe_' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try { [IO.File]::WriteAllText($probe, 'TEMP_WRITE_TEST') }
    finally { if ([IO.File]::Exists($probe)) { [IO.File]::Delete($probe) } }
    $oldTemp = [Environment]::GetEnvironmentVariable('TEMP', 'Process')
    $oldTmp = [Environment]::GetEnvironmentVariable('TMP', 'Process')
    try {
        $env:TEMP = $full
        $env:TMP = $full
        if ([IO.Path]::GetTempPath().TrimEnd('\') -ine $full) { throw 'Windows did not resolve the requested temporary directory.' }
        & $Action $full
    } finally {
        [Environment]::SetEnvironmentVariable('TEMP', $oldTemp, 'Process')
        [Environment]::SetEnvironmentVariable('TMP', $oldTmp, 'Process')
    }
}

Export-ModuleMember -Function Get-ResolveTempLocation, Test-ResolveInstallerSignature, Invoke-WithTemporaryDirectory
