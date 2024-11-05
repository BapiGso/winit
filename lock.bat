@echo off
chcp 65001

:: BatchGotAdmin
::-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
 
REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )
 
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B
 
:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
 
setlocal enabledelayedexpansion
 
:: 寻找当前目录中的后缀为 .vhdx 的文件
set "search_dir=%~dp0"
set "extension=.vhdx"
set "vhdx_file="
 
for %%f in ("%search_dir%*%extension%") do (
    set "vhdx_file=%%~nxf"
    goto :MountDisk
)
 
:MountDisk
if not defined vhdx_file (
    echo 未找到后缀为 .vhdx 的文件
    goto :End
)
 
set DiskFile=%vhdx_file%
set DiskLabel=MyVirtualDisk
 
:: 创建一个包含diskpart命令的临时脚本文件
echo select vdisk file="%~dp0%DiskFile%" > temp_diskpart_script.txt
echo attach vdisk >> temp_diskpart_script.txt
:: 运行diskpart来执行临时脚本
diskpart /s temp_diskpart_script.txt
 
:: 删除临时脚本文件
del temp_diskpart_script.txt
 
echo 磁盘已挂载到 %DiskLabel%
 
:: 输入 BitLocker 密码
echo 输入解锁这个隐藏在电脑里的秘密磁盘
manage-bde -unlock G: -password
 
:: 等待用户输入
echo 按任意键拔掉这个非常非常非常牛逼的磁盘
pause
 
:: 卸载（弹出）虚拟磁盘
echo 卸载虚拟磁盘 %DiskLabel%
echo select vdisk