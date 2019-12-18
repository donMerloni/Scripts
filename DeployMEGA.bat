:: This script zips a directory into a self-extracting archive.
:: The archive is then uploaded to the specified MEGA remote path
:: and moved to the specified local path.
:: Also creates an URL shortcut for the MEGA link.
:: !! Requires MegaCMD, 7z and 7z LZMA SDK in environment PATH variable

:: %1 = Path to the directory to be zipped
:: %2 = Name of the SFX archive (without extension)
:: %3 = MEGA remote path where archives are uploaded to
:: %4 = Local path where archives are moved to
:: Usage examples:
::   Deploy "C:\MyCoolApp\bin\Release" "MyCoolApp-Release" "/Remote_Package_Folder" "D:\Local_Package_Folder"
@echo off
set "dirPath=%~f1"
set "dirName=%~nx1"
set "sfxName=%~2"
set "remoteSavePath=%~3"
set "localSavePath=%~f4"
path %~dp0;%path%
setlocal EnableDelayedExpansion

:: Remove trailing slashes for directory paths
if "!dirPath:~-1!"=="\" set "dirPath=!dirPath:~0,-1!"
if "!localSavePath:~-1!"=="\" set "localSavePath=!localSavePath:~0,-1!"

pushd "!dirPath!"
    :: Create self extracting archive
    7z a -t7z -mx=9 "..\!sfxName!.7z" "!dirPath!\"
    7z rn "..\!sfxName!.7z" "!dirName!/" "!sfxName!/"
    for /F "tokens=*" %%S in ('where 7z.sfx') do set "sfx=%%~S"
    copy /b "!sfx!" + "..\!sfxName!.7z" "..\!sfxName!.exe"
    del "..\!sfxName!.7z"

    :: Upload to MEGA
    call mega-put "..\!sfxName!.exe" "!remoteSavePath!"
    
    :: Create URL shortcut
    for /F "tokens=3" %%L in ('mega-export -a "!remoteSavePath!/!sfxName!.exe"') do set "url=%%~L"
    echo start "" "!url!" >"!localSavePath!\!sfxName! URL.cmd"
    :: Move to local save path
    move "..\!sfxName!.exe" "!localSavePath!"
popd

exit /b 0