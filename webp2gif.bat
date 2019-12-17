:: Converts a .WebP file to .gif
:: !! Requires ffmpeg, webpinfo and anim_dump (libwebp) in environment PATH variable
:: %1 = Path to the WebP file
:: Usage examples:
::   webp2gif MyFile.webp
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
    
    if not exist "!prefix!concat.txt" (
        echo file '!prefix!0000.png' >>"!prefix!concat.txt"
        echo duration 10000 >>"!prefix!concat.txt"
    )

    call :make_gif "!fileName!" diff bayer 5 rectangle 0
    
    :: The code below generates a gif for each possible combination of ffmpeg settings. File name
    REM for %%S in (full diff single) do (
        REM for %%D in (bayer heckbert floyd_steinberg sierra2 sierra2_4a) do (
            REM for /L %%B in (0,1,5) do (
                REM call :make_gif "!fileName!" %%S %%D %%B none 0
                REM call :make_gif "!fileName!" %%S %%D %%B none 1
                REM call :make_gif "!fileName!" %%S %%D %%B rectangle 0
                REM call :make_gif "!fileName!" %%S %%D %%B rectangle 1
            REM )
        REM )
    REM )
    
    del "!prefix!*"
popd
@echo on
echo move "!tempDir!\!fileName!.gif" .
move "!tempDir!\!fileName!.gif" .
if %rd% equ 1 rd "!tempDir!"
exit /b

:make_gif filename stats_mode dither bayer_scale diff_mode new
setlocal EnableDelayedExpansion
    if "%3"=="bayer" (set "filename=%~1_%2-%3%4-%5") else (
        if %4 gtr 0 exit /b
        set "filename=%~1_%2-%3-%5"
    )
    if %6 equ 1 set "filename=%filename%-new"
    set "filename=%filename:-none=%.gif"
    if not "%~1"=="" set "filename=%~1.gif"
    ffmpeg -f concat -i "!prefix!concat.txt" -vf "split[i0][i1],[i0]palettegen=stats_mode=%2[p],[i1][p]paletteuse=%3:%4:%5:%6" "%filename%"
endlocal
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