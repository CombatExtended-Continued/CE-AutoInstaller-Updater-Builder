@Echo off
echo HobGoblin's Fast Lazy Installer and Updater for Combat Extended :D

:: Check if dotnet is installed
dotnet --version >nul 2>&1
if %errorlevel% neq 0 (
    echo .NET SDK is not installed. Attempting to install it using winget...
    winget install --id=Microsoft.dotnet.SDK.8
    if %errorlevel% neq 0 (
        echo .NET SDK is not installed. Please download and install it from https://dotnet.microsoft.com/download/dotnet/8.0 manually, and then re-run the script.
        pause
        exit /b 1
    )
)

:: Continue to Check if Git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Git is not installed. Attempting to install Git using winget...
    winget install --id Git.Git -e --source winget
    if %errorlevel% neq 0 (
        echo Failed to install Git. Please install it manually from https://git-scm.com/ and re-run the script.
        pause
        exit /b 1
    )
)

:: Continue with Mods folder verifier

CALL :ModsFolderVerifier

:: Set this to true if you only want to update and don't want to install mods!
set DONTINSTALL=false

:: Simply delete the line below with the mods you don't want to install then run to auto-install and auto-update!
CALL :GitUpdate CombatExtended https://github.com/CombatExtended-Continued/CombatExtended.git

echo.
ECHO If you're running this for the first time, run it again to build the assembly files! Every time you run this Updater after the initial run, it will pull the latest dev files and rebuild the assembly files.
pause
EXIT 0

:GitUpdate
echo.

set ModFolderName=%~1
if exist %~1-master/ set ModFolderName=%~1-master

if exist %ModFolderName%/ (
    echo Updating %ModFolderName%...
    cd %ModFolderName%
    if exist .git (
        git reset --hard HEAD
        git fetch
        git pull --rebase
        echo Building .sln files in the Source directory...
        for /r %%I in (Source\*.sln) do (
            echo Building %%~nI...
            pushd "%%~dpI"
            dotnet build "%%~nxI"
            popd
        )
        cd ..
    ) else (
        cd ..
        if %DONTINSTALL%==true EXIT /B 0
        echo .git not found in /%ModFolderName%/.
        set /P INPUT=Would you like to DELETE /%ModFolderName%/ and reinstall correctly for auto-update? [IAMSURE/n]: 
        CALL :GitRemoveInstall %ModFolderName% %~2
    )
) else (
    if %DONTINSTALL%==true EXIT /B 0
    set /P INPUT=/Mods/%ModFolderName%/ folder not found. Would you like to install? [y/n]: 
    CALL :GitInstall %~2
    echo Building .sln files in the Source directory...
    for /r "Source" %%I in (*.sln) do (
        echo Building %%~nI...
        pushd "%%~dpI"
        dotnet build "%%~nxI"
        popd
    )
)

EXIT /B 0

:GitOnlyCheckInstalled
echo.
echo Checking if %~1 installed...
set FolderExists=N
if exist %~1 set FolderExists=Y
if exist %~1-master set FolderExists=Y
if %FolderExists%==N (
    set /P INPUT=/Mods/%~1/ folder not found. Would you like to install? [y/n]: 
    CALL :GitInstall %~2
    echo Building .sln files in the Source directory...
    for /r "Source" %%I in (*.sln) do (
        echo Building %%~nI...
        pushd "%%~dpI"
        dotnet build "%%~nxI"
        popd
    )
) else echo %~1 is installed.

EXIT /B 0

:GitInstall
if /I %INPUT%==y git clone %~1
set INPUT=n
EXIT /B 0

:GitRemoveInstall
if /I %INPUT%==IAMSURE ( 
    echo Deleting and reinstalling mod /%~1/...
    RMDIR /S /Q "%~1"
    git clone %~2
    set INPUT=n
)
EXIT /B 0

:ModsFolderVerifier
for %%I in (.) do set CurrDirName=%%~nxI
if NOT %CurrDirName%==Mods (
    echo Please place me in your RimWorld/Mods/ folder to run!
    pause
    EXIT 0
)
EXIT /B 0
