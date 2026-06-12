#Requires -Version 5.1
$ErrorActionPreference = 'Continue'

# ============================================================
# Chrome（同步，前台等待）
# ============================================================
function Install-Chrome {
    $chromePaths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    )
    if ($chromePaths | Where-Object { Test-Path $_ }) {
        Write-Host 'Chrome already installed, skipping.'
        return
    }
    $installer = Join-Path $env:TEMP 'ChromeInstaller.exe'
    Write-Host 'Downloading Chrome...'
    (New-Object System.Net.WebClient).DownloadFile(
        'https://dl.google.com/chrome/install/standalonesetup64.exe',
        $installer
    )
    Start-Process -FilePath $installer -ArgumentList '/silent', '/install' -Wait
    Remove-Item $installer -ErrorAction SilentlyContinue
}

# ============================================================
# Steam（后台 Job）
# ============================================================
function Install-Steam {
    if (Test-Path "${env:ProgramFiles(x86)}\Steam\Steam.exe") {
        Write-Host 'Steam already installed, skipping.'
        return $null
    }
    Start-Job -Name 'InstallSteam' -ScriptBlock {
        $setup = Join-Path $env:TEMP 'SteamSetup.exe'
        Invoke-WebRequest -Uri 'https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe' -OutFile $setup
        Start-Process -FilePath $setup -ArgumentList '/S' -Wait
        Remove-Item $setup -ErrorAction SilentlyContinue
    }
}

# ============================================================
# Scoop bootstrap（必须同步，下面要立即用）
# ============================================================
function Install-Scoop {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        return
    }
    [Environment]::SetEnvironmentVariable('SCOOP', 'D:\ScoopApps', 'User')
    [Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', 'D:\GlobalScoopApps', 'Machine')
    $env:SCOOP = 'D:\ScoopApps'
    $env:SCOOP_GLOBAL = 'D:\GlobalScoopApps'

    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-Expression (New-Object Net.WebClient).DownloadString('https://get.scoop.sh')
    scoop install git
    Install-Module PSReadLine -MinimumVersion 2.0.3 -Scope CurrentUser -Force
}

# ============================================================
# PowerShell 7 + powershell.exe shim（Agent/IDE 友好）
# ============================================================
function Set-PathEntryFirst {
    param(
        [ValidateSet('User', 'Machine')]
        [string]$Scope,
        [string]$Entry
    )
    $path = [Environment]::GetEnvironmentVariable('Path', $Scope)
    $entries = @()
    if (-not [string]::IsNullOrWhiteSpace($path)) {
        $entries = $path -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }
    $normalized = $Entry.TrimEnd('\')
    $entries = @($Entry) + @($entries | Where-Object { $_.TrimEnd('\') -ine $normalized })
    [Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), $Scope)
}

function Install-PowerShell7 {
    $scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { 'D:\ScoopApps' }
    $scoopShims = Join-Path $scoopRoot 'shims'

    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        scoop install pwsh
    }

    $pwshPath = @(
        (Join-Path $scoopRoot 'apps\pwsh\current\pwsh.exe'),
        (Join-Path $scoopRoot 'apps\powershell\current\pwsh.exe'),
        (Get-Command pwsh -ErrorAction SilentlyContinue).Source,
        (Join-Path $scoopShims 'pwsh.exe')
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

    if (-not $pwshPath) {
        Write-Warning 'PowerShell 7 (pwsh.exe) not found, skipping powershell.exe shim.'
        return
    }

    $profilePath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\profile.ps1'
    $profileDir = Split-Path -Parent $profilePath
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    $profileBlock = @(
        '# Codex-friendly UTF-8 defaults'
        '[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)'
        '[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)'
        '$OutputEncoding = [System.Text.UTF8Encoding]::new($false)'
        '$PSDefaultParameterValues[''Out-File:Encoding''] = ''utf8'''
        'if ($Host.Name -eq ''ConsoleHost'') { chcp.com 65001 > $null }'
    ) -join [Environment]::NewLine
    if (Test-Path $profilePath) {
        $profileContent = Get-Content -Path $profilePath -Raw
        if ($profileContent -notlike '*Codex-friendly UTF-8 defaults*') {
            Add-Content -Path $profilePath -Value "`n$profileBlock`n"
        }
    } else {
        Set-Content -Path $profilePath -Value $profileBlock -Encoding UTF8
    }

    $powershellShim = Join-Path $scoopShims 'powershell.shim'
    $needsShim = $true
    if (Test-Path $powershellShim) {
        $needsShim = -not (Get-Content -Path $powershellShim -Raw).Contains($pwshPath)
    }
    if ($needsShim) {
        if (Test-Path $powershellShim) {
            scoop shim rm powershell
        }
        scoop shim add powershell $pwshPath
    }

    Set-PathEntryFirst -Scope User -Entry $scoopShims
    try {
        Set-PathEntryFirst -Scope Machine -Entry $scoopShims
    } catch {
        Write-Warning "Could not promote $scoopShims in Machine PATH: $_"
    }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

    Write-Host "PowerShell 7 ready: $pwshPath"
    Write-Host "powershell.exe shim: $(Join-Path $scoopShims 'powershell.exe')"
}
# ============================================================
# Scoop buckets + 一次性批量安装
# ============================================================
function Install-ScoopPackages {
    scoop bucket add extras
    scoop bucket add nonportable

    $packages = @(
        'alpinewsl'                       # WSL Alpine
        'blender'                         # 3D 建模/动画
        'claude-code'                     # Claude Code CLI
        'cuda'                            # NVIDIA 并行计算
        'ddu'                             # Display Driver Uninstaller
        'ffmpeg'                          # 多媒体处理
        'foobar2000'                      # 音频播放器
        'frp'                             # 端口转发
        'go'                              # Go 编译器
        'go-size-analyzer'                # Go 二进制分析
        'goland'                          # Go IDE
        'goland-eap'                      # Go IDE 预览版
        'hxd'                             # 十六进制编辑器
        'imageglass'                      # 图像查看器
        'jamovi'                          # 统计软件
        'monero'                          # 加密货币
        'msys'                            # MSYS shell
        'musescore'                       # 乐谱
        'nvidia-display-driver-dch-np'    # NVIDIA 驱动
        'obs-studio'                      # 录屏/直播
        'office-tool-plus'                # Office 工具
        'openssh'                         # SSH 客户端
        'pycharm'                         # Python IDE
        'qbittorrent-enhanced'            # BT 客户端
        'reaper'                          # DAW
        'rustdesk'                        # 远程桌面
        'scrcpy'                          # Android 镜像
        'sqlitebrowser'                   # SQLite GUI
        'sumatrapdf'                      # PDF 阅读
        'telegram'                        # IM
        'v2rayn-desktop'                  # V2Ray 客户端
        'vlc'                             # 媒体播放器
        'zed'                             # 编辑器
    )
    scoop install @packages
}

# ============================================================
# 任务栏/标题栏主题色（后台）
# ============================================================
function Set-AccentColor {
    Start-Job -Name 'AccentColor' -ScriptBlock {
        Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'ColorPrevalence' -Value 1
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoColorization' -Value 1
        Stop-Process -ProcessName explorer -Force
        # explorer 由 WinLogon 自动重启，无需 Start-Process
    }
}

# ============================================================
# Ryzen 电源管理高级选项可见
# ============================================================
function Enable-RyzenPowerOption {
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\75b0ae3f-bce0-45a7-8c89-c9611c25e100'
    if (Test-Path $path) {
        Set-ItemProperty -Path $path -Name 'Attributes' -Value 2 -Type DWord
    }
}

# ============================================================
# WSL Debian（后台）
# ============================================================
function Install-WslDebian {
    Start-Job -Name 'WslDebian' -ScriptBlock {
        wsl.exe --install -d Debian
    }
}

# ============================================================
# 电源方案重置
# ============================================================
function Reset-PowerSchemes {
    powercfg -restoredefaultschemes
    powercfg /L
}

# ============================================================
# 主流程
# ============================================================
Install-Chrome

$jobs = New-Object System.Collections.Generic.List[object]
$null = $jobs.Add((Install-Steam))

Install-Scoop
Install-PowerShell7
Install-ScoopPackages

$null = $jobs.Add((Set-AccentColor))
Enable-RyzenPowerOption
$null = $jobs.Add((Install-WslDebian))
Reset-PowerSchemes

# 收割后台任务，输出转发到主控制台
$active = $jobs | Where-Object { $_ }
if ($active) {
    Write-Host "Waiting for $($active.Count) background job(s)..."
    $active | Wait-Job | Receive-Job
    $active | Remove-Job
}
Write-Host 'init.ps1 finished.'


