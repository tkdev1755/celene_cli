# Variables
$projectRoot = "$env:USERPROFILE\celene_cli"
$apiWindowsPath = "$projectRoot\lib\model\KeychainAPI\windows"
$outputPath = "$projectRoot\bin\windows_x64"

# Crée le dossier de sortie s'il n'existe pas
if (!(Test-Path -Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath
}

# 1. Compiler l'application Dart
Write-Host "Compilation de l'application Dart..."
Push-Location $projectRoot
dart compile exe bin/celene_cli.dart
Pop-Location

# 2. Compiler le binaire C avec Makefile
Write-Host "Compilation du binaire C..."
Push-Location $apiWindowsPath
make
Pop-Location

# 3. Déplacer app.exe
$appExePath = "$projectRoot\bin\celene_cli.exe"
if (Test-Path $appExePath) {
    Write-Host "Déplacement de app.exe..."
    Move-Item -Path $appExePath -Destination $outputPath -Force
} else {
    Write-Warning "app.exe introuvable après la compilation Dart."
}

# 4. Déplacer app.dll
$appDllPath = "$apiWindowsPath\libkeychain.dll"
if (Test-Path $appDllPath) {
    Write-Host "Déplacement de libkeychain.dll..."
    Move-Item -Path $appDllPath -Destination $outputPath -Force
} else {
    Write-Warning "libkeychain.dll introuvable après la compilation du C."
}

Write-Host "Toutes les opérations sont terminées."