$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

# Install Steam silently
Start-Job -ScriptBlock {
    # Download Steam installer
    Invoke-WebRequest -Uri "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" -OutFile "$env:TEMP\SteamSetup.exe"
    Start-Process -FilePath "$env:TEMP\SteamSetup.exe" -ArgumentList '/S' -Wait
}

# https://blog.bling.moe/post/11/
# 设置 PowerShell 执行策略
[Environment]::SetEnvironmentVariable('SCOOP', 'D:\ScoopApps', 'User');
[Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', 'D:\GlobalScoopApps', 'Machine');

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
iex (new-object net.webclient).downloadstring('https://get.scoop.sh')
scoop install git
scoop bucket add extras
scoop bucket add dorado https://github.com/chawyehsu/dorado


# 使用Scoop安装
scoop install vlc
scoop install foobar2000
scoop install ffmpeg
scoop install obs-studio
scoop install qbittorrent-enhanced
scoop install sqlitebrowser
scoop install putty
scoop install hxd
scoop install blender
scoop install goland
scoop install reaper
scoop install pycharm
scoop install sumatrapdf
scoop install v2rayn
scoop install rustdesk
scoop install imageglass
scoop install go
scoop install ollama
scoop install msys


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