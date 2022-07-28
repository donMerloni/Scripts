@echo off
setlocal EnableDelayedExpansion

call :FindVisualStudio
call :FindVisualStudioLegacy
call :SelectVisualStudio %*

if "%_VS%"=="" (
	echo No Visual Studio installation found
	exit /b 1
)

@REM This is faster but dunno if I should hardcode \VC\
@REM for /F "tokens=*" %%A in ('dir "%_VS%\VC\vcvarsall.bat" /S /B') do set "pathToAdd=%%~dpA"
for /F "tokens=*" %%A in ('where /R "%_VS%" vcvarsall.bat') do set "pathToAdd=%%~dpA"
if "%pathToAdd%"=="" exit /b 1

call set "path2=%%path:%pathToAdd%=%%"
if "!path2!"=="%path%" (
	echo Adding "!pathToAdd!" to environment PATH
	set "path=!pathToAdd!;%path%"
) else (
	echo Environment PATH already contains "!pathToAdd!"
	exit /b 1
)

endlocal & set "path=%path%"
exit /b 0

:FindVisualStudio
set _VSCount=0
for /F "tokens=* skip=1 usebackq" %%A in (`
	reg query HKEY_LOCAL_MACHINE\Software\Microsoft /f VisualStudio_ /reg:32 2^>nul
`) do (
	set "regPath=%%~A"
	set "valid=0"
	for /F "tokens=1,2* usebackq" %%X in (`
		reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\!regPath:~-8!" /reg:32 2^>nul
	`) do (
		set "VisualStudio[!_VSCount!].%%~X=%%~Z"
		set "valid=1"
	)
	
	if !valid! equ 1 (
		call set InstallLocation=%%VisualStudio[!_VSCount!].InstallLocation%%\
		if exist "!InstallLocation!\\" (
			set /a _VSCount+=1
			set "_VSHave[!InstallLocation:~2!]=1"
		)
	)
)
exit /b

:FindVisualStudioLegacy
for /F "tokens=1,2* usebackq" %%A in (`
	reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\VisualStudio\SxS\VS7 /s /reg:32 2^>nul
`) do if exist "%%~C\\" (
	set "InstallLocation=%%~C"
	call set "alreadyAdded=%%_VSHave[!InstallLocation:~2!]%%"
	if not !alreadyAdded! equ 1 (		
		set "name="
		if "%%~A"=="9.0"  (set "name=Visual Studio 2008") else (
		if "%%~A"=="10.0" (set "name=Visual Studio 2010") else (
		if "%%~A"=="11.0" (set "name=Visual Studio 2012") else (
		if "%%~A"=="12.0" (set "name=Visual Studio 2013") else (
		if "%%~A"=="14.0" (set "name=Visual Studio 2015") else (
		if "%%~A"=="15.0" (set "name=Visual Studio 2017"))))))
		
		if not "!name!"=="" (
			set "VisualStudio[!_VSCount!].DisplayName=!name!"
			set "VisualStudio[!_VSCount!].DisplayVersion=%%~A"
			set "VisualStudio[!_VSCount!].InstallLocation=%%~C"
			set /a _VSCount+=1
		)
	)
)
exit /b

:SelectVisualStudio
if %_VSCount% gtr 1 (
	set /a _VSCount-=1
	if not "%~1"=="" (set "_VS=%~1") else (
		for /L %%I in (0,1,!_VSCount!) do (
			echo %%I: !VisualStudio[%%I].DisplayName! ^(!VisualStudio[%%I].DisplayVersion!^, installed on !VisualStudio[%%I].InstallDate!^) "!VisualStudio[%%I].InstallLocation!"
		)
		set /p "_VS=SELECT ONE VERSION [0-!_VSCount!]: "
	)
	if !_VS! gtr !_VSCount! set "_VS=!_VSCount!"
	call set "_VS=%%VisualStudio[!_VS!].InstallLocation%%"
)
if "!_VS!"=="" set "_VS=%VisualStudio[0].InstallLocation%"
exit /b
