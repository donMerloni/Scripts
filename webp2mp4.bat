:: Converts a .WebP file to .MP4
:: !! Requires ffmpeg, webpinfo and anim_dump (libwebp) in environment PATH variable
:: %1 = Path to the WebP file
:: Usage examples:
::   webp2mp4 MyFile.webp
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

    echo Extracting frame durations to !tempDir!\!prefix!concat.txt
    set "frameNumber=0"
    for /F "tokens=1,2" %%A in ('webpinfo -summary "!filePath!"') do (
        if "%%~A"=="Duration:" (
            call :PadLeft !frameNumber! 4 0 name
            echo file '!prefix!!name!.png' >>"!prefix!concat.txt"
            call :PadLeft %%B 4 0 duration
            set duration=!duration:~0,-3!.!duration:~-3!
            echo duration !duration! >>"!prefix!concat.txt"
            set /a "frameNumber+=1"
        )
    )

    ffmpeg -f concat -i "!prefix!concat.txt" -pix_fmt yuv420p "!fileName!.mp4"
    del "!prefix!*"
popd
move "!tempDir!\!fileName!.mp4" .
if %rd% equ 1 rd "!tempDir!"
exit /b

:PadLeft string padLength padChar outVar
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