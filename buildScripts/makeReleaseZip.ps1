# Stop en cas d'erreur
$ErrorActionPreference = "Stop"

# Vérification du paramètre
if ($args.Count -ne 3) {
    Write-Host "❌ Utilisation : .\build_and_package.ps1 [macos|linux] <ARCH> <VERSION>" -ForegroundColor Red
    exit 1
}

$target = $args[0]
$arch = $args[1]
$version = $args[2]

# Définition des chemins
$projectDir = "$env:USERPROFILE\celene_cli"
$binDir = ""
$buildScript = ""
$installScriptPath = "$projectDir\install.bat"

# Sélection du script de build et du dossier selon la cible
switch ($target.ToLower()) {
    "windows" {
        $buildScript = "buildWindows.ps1"
        $binDir = Join-Path $projectDir "bin\celeneCLI_Windows_$ARCH"
    }
    default {
        Write-Host "Paramètre invalide. Utilisez 'windows' uniquement." -ForegroundColor Red
        exit 1
    }
}

# Exécution du script de build
Write-Host "Exécution du script de build : $buildScript" -ForegroundColor Cyan
if (Test-Path $buildScript) {
    & ".\$buildScript" "$ARCH"
} else {
    Write-Host "Script de build introuvable : $buildScript" -ForegroundColor Red
    exit 1
}

# Vérification de l'existence du dossier binaire
if (!(Test-Path $binDir)) {
    Write-Host "❌ Dossier binaire introuvable : $binDir" -ForegroundColor Red
    exit 1
}

if (!(Test-Path "$projectDir\releases")) {
    New-Item -Path "$projectDir\releases" -ItemType Directory
}
# Création de l'archive ZIP
Copy-Item -Path $installScriptPath -Destination $binDir

if (!(Test-Path "$projectDir\releases\version_$VERSION")) {
    New-Item -Path "$projectDir\releases\version_$VERSION" -ItemType Directory
}

$zipFile = Join-Path "$projectDir\releases\version_$VERSION" "celeneCLI_${target}_$ARCH.zip"


# PowerShell natif (pas besoin de zip.exe !)
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

Compress-Archive -Path (Join-Path $binDir '*') -DestinationPath $zipFile