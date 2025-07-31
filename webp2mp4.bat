@echo off
setlocal
call :parse_args %*
call :check_dependencies "F:%~1" P:ffmpeg P:webpinfo P:anim_dump || goto :help
goto :start

::
:: Show help and exit.
::
:help

echo.
echo Converts a .WebP file to .mp4
echo !! requires ffmpeg, webpinfo and anim_dump (libwebp) in environment PATH
echo.
echo usage: %~n0 input.webp [ "VideoFilter=..." ]
exit /b 1

::
:: Simple command line arguments, e.g. MyScript.bat "variable1=value1" "variable2=value2"
::
:parse_args

set i=0
:parse_args_loop
    set /a i+=1
    call set "arg=%%%i%%"
    if [%arg%]==[] exit /b

    for /F %%A in ('echo %arg%') do set "arg=%%~A"
    echo %arg% | findstr /R "^[a-z0-9][a-z]*=..*$" >nul && set %arg%
    goto :parse_args_loop
exit /b

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

    set frameCount=0
    for /F %%P in ('dir /b "!prefix!*.png"') do (
        set /a frameCount+=1
        rename "%%~P" "!prefix!!frameCount!%%~xP"
    )

    echo Extracting frame durations to !tempDir!\!prefix!concat.txt
    set frameNumber=0
    for /F "tokens=1,2" %%A in ('webpinfo -summary "!filePath!"') do (
        if "%%~A"=="Duration:" (
            set /a frameNumber+=1
            echo file '!prefix!!frameNumber!.png' >>"!prefix!concat.txt"
            call :pad_left %%B 4 0 duration
            set duration=!duration:~0,-3!.!duration:~-3!
            echo duration !duration! >>"!prefix!concat.txt"
        )
    )

    if not "%VideoFilter%"=="" (
        ffmpeg -i "!prefix!%%d.png" -vf "%VideoFilter%" "!prefix!%%d.png"
    )

    if not exist "!prefix!concat.txt" (
        ffmpeg -loop 1 -i "!prefix!1.png" -t 10 -pix_fmt yuv420p "!fileName!.mp4"
    ) else (
        ffmpeg -f concat -i "!prefix!concat.txt" -pix_fmt yuv420p "!fileName!.mp4"
    )
    del "!prefix!*"
popd
move "!tempDir!\!fileName!.mp4" .
if %rd% equ 1 rd "!tempDir!"

exit /b

::
:: Pad a string to a minimum length (right-aligned).
::
:pad_left string padLength padChar outVar
setlocal EnableDelayedExpansion

set "padded=%~1"
call :strlen %1 len
set /a diff=%2-len
if %diff% gtr 0 (
    for /L %%L in (%diff%,-1,1) do (
        set "padded=%~3!padded!"
    )
)

endlocal & set "%~4=%padded%"
exit /b

::
:: Calculate string length.
::
:strlen string outVar
setlocal EnableDelayedExpansion

set "s=#%~1"
set "len=0"
for %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
    if "!s:~%%N,1!" neq "" (
    set /a "len+=%%N"
    set "s=!s:~%%N!"
    )
)

endlocal & set /a "%~2+=%len%"
exit /b
