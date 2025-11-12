@echo off
set PATH=%SYSTEMROOT%\SYSTEM32;%SYSTEMROOT%;%SYSTEMROOT%\SYSTEM32\WBEM;
chcp.com>nul 866

set PROGRAM_DIR=%ProgramFiles: (x86)=%

:: https://anydesk.com/ru/download?os=win
set PROGRAM_DESC=Удалённый доступ к ПК
set PROGRAM_NAME=AnyDesk
set PROGRAM_EXEC=anydesk.exe

set KEY=%~1
if defined SFXCMD set SFXCMD=%SFXCMD:*.exe=%
if defined SFXCMD set SFXCMD=%SFXCMD:"=%
if defined SFXCMD set    KEY=%SFXCMD: =%
if defined KEY    set    KEY=%KEY:/=-%

if /I "%KEY%"=="-sfx" goto MakeSFX

:UnInstall
taskkill.exe         >nul 2>nul /F /T /IM "%PROGRAM_EXEC%"
"%~dp0%PROGRAM_EXEC%">nul 2>nul --remove --silent
call                 >nul 2>nul :DelDirInProgs   "%PROGRAM_NAME%"
call                 >nul 2>nul :DelDirInUsers   "Videos\%PROGRAM_NAME%"
if /I "%KEY%"=="-u" ^
call                 >nul 2>nul :DelDirInAppData "%PROGRAM_NAME%"
call                 >nul 2>nul :DelShortcuts    "%PROGRAM_NAME%"
if /I "%KEY%"=="-u" goto Finish

:Install
xcopy.exe            >nul 2>nul /C /H /I /R /E /Y /Z "%~dp0Files" "%ALLUSERSPROFILE%\%PROGRAM_NAME%\"
if /I not "%KEY%"=="-c" set START_WITH_WIN=--start-with-win
"%~dp0%PROGRAM_EXEC%">nul 2>nul --install "%PROGRAM_DIR%\%PROGRAM_NAME%" --silent %START_WITH_WIN%
if /I "%KEY%"=="-c" (
  taskkill.exe       >nul 2>nul /F /T /IM "%PROGRAM_EXEC%"
  sc.exe             >nul 2>nul config "AnyDesk" start= demand
)
wscript.exe          >nul 2>nul "%~dp0shortcut.vbs" "%PROGRAM_DIR%\%PROGRAM_NAME%\%PROGRAM_EXEC%" "AllUsersPrograms" "%PROGRAM_NAME%" "%PROGRAM_DESC%"
goto Finish

:MakeSFX
setlocal
cd /D "%~dp0"
del>nul 2>nul /A /F /Q "..\%PROGRAM_NAME%.exe"
echo> "%TEMP%\makesfx.cfg" Path=%%TEMP%%\%PROGRAM_NAME%
echo>>"%TEMP%\makesfx.cfg" Overwrite=1
echo>>"%TEMP%\makesfx.cfg" Silent=1
echo>>"%TEMP%\makesfx.cfg" Setup=hidec.exe "%%COMSPEC%%" /C "install.bat %%~1 & ping.exe 127.0.0.1 -n 11 & cd .. && rmdir /S /Q "%%TEMP%%\%PROGRAM_NAME%""
if defined PROGRAM_ICON set PROGRAM_ICON=-iicon"Files\%PROGRAM_ICON%"
start /wait winrar a %PROGRAM_ICON% -z"%TEMP%\makesfx.cfg" -cfg- -ep1 -dh -s -r -m5 -sfx -kb -t "..\%PROGRAM_NAME%.exe" *
del>nul 2>nul /A /F /Q "%TEMP%\makesfx.cfg"
endlocal
goto Finish

:ExistFile
if "%~1"=="" exit /B 255
dir>nul 2>nul /A:-D "%~1" || exit /B 1
exit /B 0

:ExistDir
if "%~1"=="" exit /B 255
dir>nul 2>nul /A:D "%~1" || exit /B 1
exit /B 0

:DelFile
call>nul 2>nul :ExistFile "%~1" || exit /B
setlocal
cd /D "%~dp1"
set myname=%~1
:DelFile_Loop
if not defined myname exit /B
if "%myname%"=="%myname:*\=%" goto DelFile_Skip
set myname=%myname:*\=%
goto DelFile_Loop
:DelFile_Skip
forfiles.exe 2>nul /C "%COMSPEC% /C if @isdir==FALSE ( del /A /F /Q @path )" /M "%myname%" || del /A /F /Q "%~1"
exit /B

:DelDir
call>nul 2>nul :ExistDir "%~1" || exit /B
setlocal
cd /D "%~dp1"
set myname=%~1
:DelDir_Loop
if not defined myname exit /B
if "%myname%"=="%myname:*\=%" goto DelDir_Skip
set myname=%myname:*\=%
goto DelDir_Loop
:DelDir_Skip
forfiles.exe 2>nul /C "%COMSPEC% /C if @isdir==TRUE ( rmdir /S /Q @path )" /M "%myname%" || rmdir /S /Q "%~1"
exit /B

:DelDirInProgs
if "%~1"=="" exit /B 1
if defined ProgramFiles      call :DelDir "%ProgramFiles: (x86)=%\%~1"
if defined ProgramFiles(x86) call :DelDir "%ProgramFiles(x86)%\%~1"
for /D %%i in ("%SYSTEMDRIVE%\Users" "%SYSTEMDRIVE%\Documents and Settings") do ^
for /D %%j in ("%%~i\All Users" "%%~i\Default" "%%~i\Public" "%%~i\Администратор" "%%~i\*.*") do (
  for /D %%k in ("%%~j\AppData\Local\VirtualStore\Program Files\%~1"      ) do call :DelDir "%%~k"
  for /D %%k in ("%%~j\AppData\Local\VirtualStore\Program Files (x86)\%~1") do call :DelDir "%%~k"
)
exit /B

:DelDirInAppData
if "%~1"=="" exit /B 1
for /D %%h in (C D) do ^
for /D %%i in ("%%~h:\Users" "%%~h:\Documents and Settings") do if exist "%%~i" ^
for /D %%j in ("%%~i\All Users" "%%~i\Default" "%%~i\Все пользователи" "%%~i\*.*") do if exist "%%~j" (
  for /D %%k in ("%%~j\AppData\Local\%~1"                             ) do call :DelDir "%%~k"
  for /D %%k in ("%%~j\AppData\Local\VirtualStore\Windows\AppData\%~1") do call :DelDir "%%~k"
  for /D %%k in ("%%~j\AppData\LocalLow\%~1"                          ) do call :DelDir "%%~k"
  for /D %%k in ("%%~j\AppData\Roaming\%~1"                           ) do call :DelDir "%%~k"
  for /D %%k in ("%%~j\Application Data\%~1"                          ) do call :DelDir "%%~k"
  for /D %%k in ("%%~j\Local Settings\%~1"                            ) do call :DelDir "%%~k"
  for /D %%k in ("%%~j\Local Settings\Application Data\%~1"           ) do call :DelDir "%%~k"
)
if defined ProgramData for /D %%i in ("%PROGRAMDATA%\%~1"       ) do call :DelDir "%%~i"
if defined SystemRoot  for /D %%i in ("%SYSTEMROOT%\AppData\%~1") do call :DelDir "%%~i"
exit /B

:DelShortcuts
if "%~1"=="" exit /B 1
for /D %%i in ("%SYSTEMDRIVE%\Users" "D:\Users" "%SYSTEMDRIVE%\Documents and Settings") do ^
for /D %%j in ("%%~i\*.*" "%%~i\All Users" "%%~i\Default" "%%~i\Все пользователи") do (
  call :DelDir  "%%~j\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\%~1"
  call :DelDir  "%%~j\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\%~1"
  call :DelDir  "%%~j\AppData\Roaming\Microsoft\Windows\Start Menu\%~1"
  call :DelDir  "%%~j\Microsoft\Windows\Start Menu\Programs\Startup\%~1"
  call :DelDir  "%%~j\Microsoft\Windows\Start Menu\Programs\%~1"
  call :DelDir  "%%~j\Microsoft\Windows\Start Menu\%~1"
  call :DelDir  "%%~j\Главное меню\Программы\Автозагрузка\%~1"
  call :DelDir  "%%~j\Главное меню\Программы\%~1"
  call :DelDir  "%%~j\Главное меню\%~1"
  call :DelFile "%%~j\AppData\Roaming\ClassicShell\Pinned\%~1.lnk"
  call :DelFile "%%~j\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\%~1.lnk"
::call :DelFile "%%~j\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\%~1.lnk"
  call :DelFile "%%~j\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\%~1.lnk"
  call :DelFile "%%~j\AppData\Roaming\Microsoft\Windows\SendTo\%~1.lnk"
  call :DelFile "%%~j\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\%~1.lnk"
  call :DelFile "%%~j\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\%~1.lnk"
  call :DelFile "%%~j\AppData\Roaming\Microsoft\Windows\Start Menu\%~1.lnk"
  call :DelFile "%%~j\AppData\Roaming\Microsoft\Windows\Recent\%~1.lnk"
  call :DelFile "%%~j\Microsoft\Windows\Start Menu\Programs\Startup\%~1.lnk"
  call :DelFile "%%~j\Microsoft\Windows\Start Menu\Programs\%~1.lnk"
  call :DelFile "%%~j\Microsoft\Windows\Start Menu\%~1.lnk"
  call :DelFile "%%~j\Главное меню\Программы\Автозагрузка\%~1.lnk"
  call :DelFile "%%~j\Главное меню\Программы\%~1.lnk"
  call :DelFile "%%~j\Главное меню\%~1.lnk"
  call :DelFile "%%~j\Desktop\%~1.lnk"
  call :DelFile "%%~j\Рабочий стол\%~1.lnk"
)
if defined ProgramData (
  call :DelDir  "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\%~1"
  call :DelDir  "%ProgramData%\Microsoft\Windows\Start Menu\Programs\%~1"
  call :DelDir  "%ProgramData%\Microsoft\Windows\Start Menu\%~1"
  call :DelFile "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\%~1.lnk"
  call :DelFile "%ProgramData%\Microsoft\Windows\Start Menu\Programs\%~1.lnk"
  call :DelFile "%ProgramData%\Microsoft\Windows\Start Menu\%~1.lnk"
)
exit /B

:DelDirInUsers
if "%~1"=="" exit /B 1
setlocal
cd>nul 2>nul /D "%SYSTEMDRIVE%\Users" || cd>nul 2>nul /D "%SYSTEMDRIVE%\Documents and Settings" || exit /B 1
for /D %%i in ("*.*" "All Users" "Default") do ^
for /D %%j in ("%%~i\%~1") do rmdir /S /Q "%%~j"
exit /B

:Finish
