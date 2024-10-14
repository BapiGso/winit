# 设置默认的 Web 浏览器
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -Name "ProgId" -Value "ChromeHTML"

# 设置默认的电子邮件客户端
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\mailto\UserChoice" -Name "ProgId" -Value "mailto"

# 设置默认的媒体播放器
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.mp3\UserChoice" -Name "ProgId" -Value "WindowsMedia.AudioFile"

# 设置默认的图像查看器
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpg\UserChoice" -Name "ProgId" -Value "PhotoViewer.FileAssoc.Jpeg"
