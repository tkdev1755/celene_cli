@echo off
setlocal enabledelayedexpansion

REM Configuration
set "APP_NAME=celene_cli.exe"
set "INSTALL_DIR=%USERPROFILE%\celene_cli"

REM Détection du système d'exploitation
ver | findstr /i "Windows" > nul
if %errorlevel% neq 0 (
    echo ❌ Ce script doit être exécuté sur Windows.
    exit /b 1
)

if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)


if exist "libkeychain.dll" (
    set "LIB_FILE=libkeychain.dll"
) else (
    echo ❌ libkeychain.dll introuvable !
    exit /b 1
)

REM Copie des fichiers
copy "%APP_NAME%" "%INSTALL_DIR%\"
copy "%LIB_FILE%" "%INSTALL_DIR%\"

REM Vérification si le dossier est déjà dans le PATH utilisateur
set "CURRENT_PATH=%PATH%"
echo %CURRENT_PATH% | find /i "%INSTALL_DIR%" > nul
if %errorlevel% equ 0 (
    echo ℹ️ Le dossier %INSTALL_DIR% est déjà dans le PATH utilisateur.
) else (
    echo 🔧 Ajout de %INSTALL_DIR% au PATH utilisateur...

    REM Ajout dans la variable d'environnement utilisateur
    setx PATH "%PATH%;%INSTALL_DIR%" > nul

    echo ✅ Dossier %INSTALL_DIR% ajouté au PATH.
)

echo.
echo 🚀 L'application est maintenant installée.
echo ➡️ Lance 'app' depuis n'importe quel terminal.

endlocal
pause