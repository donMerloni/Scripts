:: Converts a .WebP file to .gif
:: !! Requires merlin1337/gifski (forked), webpinfo and anim_dump (libwebp) in environment PATH variable
:: %1 = Path to the WebP file
:: Usage examples:
::   webp2gifski MyFile.webp
@echo off
set "filePath=%~f1"
set "fileName=%~n1"
set "tempDir=%~dp0%fileName%"
set "prefix=%fileName%_"
path %~dp0;%path%
setlocal EnableDelayedExpansion

set "rd=0" & if not exist "!tempDir!" (set "rd=1" & md "!tempDir!")
pushd !tempDir!
    :: Extract .PNG frames
    anim_dump -prefix "!prefix!" "!filePath!"

    echo Extracting frame durations to !tempDir!\!prefix!frames.txt
    for /F "tokens=1,2" %%A in ('webpinfo -summary "!filePath!"') do (
        if "%%~A"=="Duration:" echo.%%~B >>"!prefix!frames.txt"
    )
    
    if not exist "!prefix!frames.txt" (
        gifski !prefix!*.png !prefix!*.png --durations 10 10 --time-unit 1 --output "!fileName!.gif"
    ) else (
        gifski !prefix!*.png --durations "!prefix!frames.txt" --output "!fileName!.gif"
    )
    del "!prefix!*"
popd
move "!tempDir!\!fileName!.gif" .
if %rd% equ 1 rd "!tempDir!"
exit /b