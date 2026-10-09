# Resolve Temp Launcher

[简体中文](README.md) · [Deutsch](README.de.md)

A small Windows launcher that redirects the DaVinci Resolve installer's temporary extraction files to a secondary local drive.

## Quick start

1. Obtain the complete installer from [Blackmagic Design](https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion). Extract the original ZIP and keep its EXE, DAT and other files together.
2. Download and extract this project's ZIP.
3. Right-click `Start-ResolveInstaller.cmd` and select **Run as administrator**.
4. Select the original installer EXE. The launcher prefers D: when sufficient space is available, otherwise the secondary fixed drive with the most free space. Its default folder is `ResolveInstallerTemp` on that drive.

Choose a writable directory explicitly from an administrator PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-ResolveInstaller.ps1 -InstallerPath "G:\Downloads\Install Resolve 21.1.1.exe" -TempDirectory "D:\MyTools\ResolveInstallerTemp"
```

Append `-CheckOnly` to validate the EXE signature, free space, temporary path resolution and write access without launching the installer. Check-only creates the requested directory and briefly writes/deletes a test file. Administrator rights are unnecessary when that directory is writable.

The default minimum is 15 GB. Use `-MinimumFreeSpaceGB 25` for a larger threshold; requirements vary by Resolve version.

## Scope and implementation

TEMP and TMP are set only in the current PowerShell process, inherited by the installer and restored afterward, including on failure. No persistent user or machine environment variables are changed.

Static inspection of a Resolve 21.1.1 Windows bootstrapper found `GetTempPathW`, whose [documented behavior](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppathw) honors TMP and TEMP. Local tests cover path resolution, write access, child-process inheritance and restoration. An actual Resolve installation has **not** been tested end to end.

This does not change the application installation directory, ProgramData, projects, drivers or Windows Installer's cache. It does not guarantee zero system-drive usage. Separately launched system services or reboot continuations may use system temporary paths. Installer files are not modified, licenses are not bypassed, data is not migrated and temporary files are not automatically cleaned up.

The launcher requires a valid Blackmagic Design Authenticode signature on the EXE. That does not authenticate the entire external DAT payload or replace malware scanning. Archive CRC tests detect corruption, not malicious content. Use official installer downloads.

If a drive root is not writable, specify another directory on the same secondary drive. Invalid signatures or a missing matching DAT are reported before any installer is started.

## Tests

On Windows PowerShell 5.1+ or PowerShell 7:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Smoke.Tests.ps1
```

Tests do not install Resolve. They cover child inheritance, environment restoration on success and failure, relative-path rejection, and unsigned-installer rejection.

## Credits and license

Project initiated and maintained by **Ender-gk**, with development assistance from **OpenAI Codex**.

Independent community project, not an official Blackmagic Design or OpenAI product or endorsement.

MIT license; see [LICENSE](LICENSE). No Resolve installers, proprietary payloads, credentials or personal data are distributed.
