$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

# Install Steam silently
Start-Job -ScriptBlock {
    # Download Steam installer
    Invoke-WebRequest -Uri "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" -OutFile "$env:TEMP\SteamSetup.exe"
    Start-Process -FilePath "$env:TEMP\SteamSetup.exe" -ArgumentList '/S' -Wait
}

Start-Job -ScriptBlock {
    # https://blog.bling.moe/post/11/
    # 设置 PowerShell 执行策略
    [Environment]::SetEnvironmentVariable('SCOOP', 'D:\ScoopApps', 'User');
    [Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', 'D:\GlobalScoopApps', 'Machine');

    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    iex (new-object net.webclient).downloadstring('https://get.scoop.sh')
    scoop install git
    scoop bucket add extras
    scoop bucket add dorado https://github.com/chawyehsu/dorado
}

# 使用Scoop安装
scoop install blender          # 开源3D建模和动画软件
scoop install ddu              # 用于显卡驱动卸载
scoop install fancontrol       # 风扇控制工具
scoop install ffmpeg           # 强大的多媒体处理工具，支持音视频转换和流处理
scoop install foobar2000       # 高度可定制的音频播放器
scoop install frp              # 开源的跨平台端口转发工具
scoop install goland           # JetBrains开发的Go语言集成开发环境（IDE）
scoop install go               # Go语言编程语言的工具链
scoop install go-size-analyzer # Go语言大小分析工具
scoop install hxd              # 十六进制编辑器，用于查看和编辑二进制文件
scoop install imageglass       # 轻量级图像查看器，支持多种图像格式
scoop install monero           # 开源的加密货币软件
scoop install msys             # 提供Unix风格的命令行环境和工具
scoop install musescore        # 开源乐谱制作软件
scoop install obs-studio       # 开源视频录制和直播软件
scoop install office-tool-plus # Office工具集
scoop install ollama           # 用于构建和运行机器学习模型的工具
scoop install openssh          # SSH客户端
scoop install pycharm          # JetBrains开发的Python集成开发环境（IDE）
scoop install putty            # SSH和Telnet客户端，用于远程访问
scoop install qbittorrent-enhanced # 开源BitTorrent客户端，增强版
scoop install reaper           # 数字音频工作站（DAW），用于录音、编辑和混音
scoop install rustdesk         # 远程桌面软件，支持跨平台访问
scoop install scrcpy            # Android屏幕录制和远程控制工具
scoop install sqlitebrowser     # SQLite数据库的可视化管理工具
scoop install sumatrapdf       # 轻量级PDF阅读器
scoop install telegram         # 开源即时通讯软件
scoop install v2rayn           # V2Ray的Windows客户端，用于科学上网
scoop install vlc              # 开源多媒体播放器，支持几乎所有音视频格式
scoop install windowsdesktop-runtime-lts # Windows桌面运行时，提供Windows桌面应用的运行环境（LTS版）


#reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpg" /t REG_SZ /d PhotoViewer.FileAssoc.Tiff /f
#reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpeg" /t REG_SZ /d PhotoViewer.FileAssoc.Tiff /f
#reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".bmp" /t REG_SZ /d PhotoViewer.FileAssoc.Tiff /f
#reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".png" /t REG_SZ /d PhotoViewer.FileAssoc.Tiff /f


Start-Job -ScriptBlock {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "ColorPrevalence" -Value 1
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoColorization" -Value 1
    Stop-Process -ProcessName explorer
    Start-Process explorer
}

Start-Job -ScriptBlock {
    wsl.exe --install -d Debian
}

Start-Job -ScriptBlock {
    powercfg /L
    powercfg -restoredefaultschemes
}