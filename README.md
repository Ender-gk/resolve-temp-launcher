# Resolve Temp Launcher

[English](README.en.md) · [Deutsch](README.de.md)

让 DaVinci Resolve Windows 安装器将临时解压文件放到非系统盘，减少安装阶段对 C 盘空间的需求。

## 使用方法

1. 从 [Blackmagic Design 官方网站](https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion)下载 Windows 安装包，解开原始 ZIP。保留相邻的 EXE、DAT 等全部文件。
2. 下载本项目的 ZIP 并解压。
3. 右键 `Start-ResolveInstaller.cmd`，选择“以管理员身份运行”。
4. 选择官方安装器 EXE。脚本优先使用有足够空间的 D 盘；否则选择空闲空间最多的非系统本地盘，在其根目录下使用 `ResolveInstallerTemp`。
5. 安装界面出现后按正常流程操作。

若根目录没有写入权限，或希望使用已有文件夹，在管理员 PowerShell 中指定路径：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-ResolveInstaller.ps1 -InstallerPath "G:\Downloads\Install Resolve 21.1.1.exe" -TempDirectory "D:\MyTools\ResolveInstallerTemp"
```

路径可以包含空格。示例是通用路径，没有包含开发者的个人安装位置。

## 先检查，不启动安装

此模式验证 EXE 签名、临时目录的空间及读写能力，并恢复当前进程的 TEMP/TMP；会创建选定的临时目录和随后删除的读写探针。它不会运行安装器，不需要管理员身份（前提是所选目录可写）。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-ResolveInstaller.ps1 -InstallerPath "G:\Downloads\Install Resolve 21.1.1.exe" -TempDirectory "D:\MyTools\ResolveInstallerTemp" -CheckOnly
```

默认要求 15 GB 可用空间。版本差异可能需要更多，可通过 `-MinimumFreeSpaceGB 25` 提高检查阈值。

## 原理和范围

脚本在启动安装器之前，仅设置当前 PowerShell 进程的 `TEMP`、`TMP`，子进程继承这些值。安装器退出或报错后恢复原值，不修改用户或系统的永久环境变量。

已静态检查的 Resolve 21.1.1 Windows 引导安装器调用 `GetTempPathW`。[微软文档](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppathw)说明该函数优先读取 TMP、TEMP。本地测试验证了目录解析、读写和环境恢复；尚未完成实际 Resolve 安装流程的端到端测试。

这是调整临时解压路径的辅助工具。主程序安装目录、ProgramData、用户项目、驱动、Windows Installer 缓存仍按官方安装器和 Windows 的规则处理。不能承诺 C 盘完全零占用；另行启动的系统服务或重启后续任务也可能使用系统临时目录。

不修改安装包，不绕过 Studio 授权，不迁移数据，不创建 Junction，不自动删除安装残留。安装完成并确认没有待完成任务后，可以自行检查临时目录再清理。

## 安装包检查的边界

启动前要求 EXE 的 Authenticode 签名有效，签署者为 Blackmagic Design。签名验证不替代防病毒检测，也不会验证整个外部 DAT 文件的来源。7-Zip 的完整性测试同样只能检测压缩数据损坏。请使用官方来源的完整安装包。

## 故障处理

- 提示管理员权限：以管理员身份运行 CMD 或 PowerShell。
- 提示写入失败：通过 `-TempDirectory` 指定有权限写入的非系统盘目录。
- 提示签名无效：停止执行，从官方渠道重新获取安装器。
- 提示 DAT 缺失：保留原始安装包中相邻的所有文件，选择匹配的 EXE。
- 出现安装器错误：参照官方安装日志；本工具不会修复安装器本身的问题。

## 测试

Windows PowerShell 5.1+ 或 PowerShell 7：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Smoke.Tests.ps1
```

测试检查子进程继承、成功和异常情况下的环境恢复、相对路径拒绝及无签名文件拒绝，不安装 Resolve。

## 署名与许可证

项目发起与维护：**Ender-gk**。开发协助：**OpenAI Codex**。

这是独立社区项目，并非 Blackmagic Design 或 OpenAI 官方产品；不存在官方背书。

MIT License，见 [LICENSE](LICENSE)。DaVinci Resolve 安装器、DAT、商业组件和个人数据不随本项目分发。
