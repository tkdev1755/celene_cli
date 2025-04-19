# Stop en cas d'erreur
$ErrorActionPreference = "Stop"

# Vérification du paramètre
if ($args.Count -ne 2) {
    Write-Host "❌ Utilisation : .\build_and_package.ps1 [macos|linux] <ARCH> <VERSION>" -ForegroundColor Red
    exit 1
}

$target = $args[0]
$arch = $args[1]
$version = $args[2]
# Définition des chemins
$projectDir = "$env:USERPROFILE\celene_cli\"
$binDir = ""
$buildScript = ""

# Sélection du script de build et du dossier selon la cible
switch ($target.ToLower()) {
    "macos" {
        $buildScript = "buildMacos.sh"
        $binDir = Join-Path $projectDir "bin\mac_X86"
    }
    "windows" {
        $buildScript = "buildWindows.ps1"
        $binDir = Join-Path $projectDir "bin\celeneCLI_Windows_$ARCH"
    }
    default {
        Write-Host "❌ Paramètre invalide. Utilisez 'windows'." -ForegroundColor Red
        exit 1
    }
}

# Exécution du script de build
Write-Host "🚀 Exécution du script de build : $buildScript" -ForegroundColor Cyan
if (Test-Path $buildScript) {
    $buildScript
} else {
    Write-Host "❌ Script de build introuvable : $buildScript" -ForegroundColor Red
    exit 1
}

# Vérification de l'existence du dossier binaire
if (!(Test-Path $binDir)) {
    Write-Host "❌ Dossier binaire introuvable : $binDir" -ForegroundColor Red
    exit 1
}

# Création de l'archive ZIP
$zipFile = Join-Path $projectDir "${target}_x86_package.zip"

Write-Host "📦 Compression du contenu de $binDir dans $zipFile ..." -ForegroundColor Yellow

# PowerShell natif (pas besoin de zip.exe !)
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

Compress-Archive -Path "$binDir\*" -DestinationPath $zipFile

