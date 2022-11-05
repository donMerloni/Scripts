@echo off
call :check_dependencies "D:%~1" "V:%~2" "V:%~3" "V:%~4" P:MEGAclient P:7z P:7z.sfx || goto :help
goto :start

::
:: Show help and exit.
::
:help

echo.
echo Zips a directory into a self-extracting archive (SFX).
echo The archive is then uploaded to the specified MEGA remote path
echo and moved to the specified local path.
echo Also creates an URL shorcut for the MEGA share link.
echo !! requires MEGAcmd, 7z and 7z LZMA SDK in environment PATH
echo.
echo usage: %~n0 target_directory archive_name MEGA_path local_path
echo usage: %~n0 "C:\MyCoolApp\bin\Release" "MyCoolApp-Release" "/Uploaded Packages" "D:\Local Packages"
exit /b 1

::
:: Determine whether all specified input files (F:XXX), input directories (D:XXX), input values (V:XXX) and external programs (P:XXX) are present. Returns 1, if any are missing.
::
:check_dependencies
setlocal EnableDelayedExpansion

set R=0
set I=1
for %%A in (%*) do (
    set "V=%%~A"
    set "T=!V:~0,1!"
    set "V=!V:~2!"
    if /I "!T!"=="F" (
        2>nul>nul type "!V!" || (echo error: Input file [!I!] "!V!" not found & set R=1)
    ) else if /I "!T!"=="D" (
        if not exist "!V!\\" (echo error: Input directory [!I!] "!V!" not found & set R=1)
    ) else if /I "!T!"=="P" (
        where /Q "!V!" || (echo error: Required program ^(!V!^) missing from environment PATH & set R=1)
    ) else if "!V!"=="" (echo error: Required value [!I!] is missing & set R=1)
    set /a I+=1
)

endlocal & exit /b %R%

::
:: The actual script.
::
:start

setlocal DisableDelayedExpansion
set "dirPath=%~f1"
set "dirName=%~nx1"
set "sfxName=%~2"
set "remoteSavePath=%~3"
set "localSavePath=%~f4"
path %~dp0;%path%
setlocal EnableDelayedExpansion

:: remove trailing slashes for directory paths
if "!dirPath:~-1!"=="\" set "dirPath=!dirPath:~0,-1!"
if "!localSavePath:~-1!"=="\" set "localSavePath=!localSavePath:~0,-1!"

pushd !dirPath!
    :: create self extracting archive
    7z a -t7z -mx=9 "..\!sfxName!.7z" "!dirPath!\"
    7z rn "..\!sfxName!.7z" "!dirName!/" "!sfxName!/"
    for /F "tokens=*" %%S in ('where 7z.sfx') do set "sfx=%%~S"
    copy /b "!sfx!" + "..\!sfxName!.7z" "..\!sfxName!.exe"
    del "..\!sfxName!.7z"

    :: upload to MEGA
    MEGAclient put "..\!sfxName!.exe" "!remoteSavePath!"
    
    :: move to local save path
    2>nul md "!localSavePath!"
    move "..\!sfxName!.exe" "!localSavePath!"

    :: create URL shortcut
    for /F "tokens=3" %%L in ('MEGAclient export -a "!remoteSavePath!/!sfxName!.exe"') do set "url=%%~L"
    echo start "" "!url!" >"!localSavePath!\!sfxName! URL.cmd"
popd

exit /b 0
