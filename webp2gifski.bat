@echo off
call :check_dependencies "F:%~1" P:gifski P:webpinfo P:anim_dump || goto :help
goto :start

::
:: Show help and exit.
::
:help

echo.
echo Converts a .WebP file to a high-quality .gif
echo !! requires merlin1337/gifski (Fork), webpinfo and anim_dump (libwebp) in environment PATH
echo.
echo usage: %~n0 input.webp
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
set "filePath=%~f1"
set "fileName=%~n1"
set "tempDir=%~dp0%fileName%"
set "prefix=%fileName: =_%_"
path %~dp0;%path%
setlocal EnableDelayedExpansion

set "rd=0" & if not exist "!tempDir!" (set "rd=1" & md "!tempDir!")
pushd !tempDir!
    :: extract .PNG frames
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
