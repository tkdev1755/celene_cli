#!/bin/bash

set -e  # Stop en cas d'erreur

# Vérification du paramètre
if [ "$#" -ne 3 ]; then
    echo "Utilisation : $0 [macos|linux] <ARCH> <VERSION>"
    exit 1
fi

TARGET="$1"
ARCH="$2"
VERSION="$3"
# Chemins
PROJECT_DIR=$CELENE_CLI_PROJROOT
BIN_DIR="$PROJECT_DIR/bin/"
BUILD_SCRIPT="$PROJECT_DIR/buildScripts/"

# Définir les chemins selon le paramètre
if [ "$TARGET" == "macos" ]; then
    BUILD_SCRIPT="$PROJECT_DIR/buildScripts/buildMacOS.sh"
    BIN_DIR="${PROJECT_DIR}/bin/celeneCli_macOS_$ARCH"
elif [ "$TARGET" == "linux" ]; then
    BUILD_SCRIPT="$PROJECT_DIR/buildScripts/buildLinux.sh"
    BIN_DIR="$PROJECT_DIR/bin/celeneCli_linux_$ARCH"
else
    echo "Paramètre invalide. Utilisez 'macos' ou 'linux'."
    exit 1
fi

# Exécuter le script de build
echo "🚀 Exécution du script de build : $BUILD_SCRIPT"
if [ -f "$BUILD_SCRIPT" ]; then
    "$BUILD_SCRIPT" $ARCH
else
    echo "❌ Script de build introuvable : $BUILD_SCRIPT"
    exit 1
fi

# Vérification de l'existence du dossier binaire
if [ ! -d "$BIN_DIR" ]; then
    echo "❌ Dossier binaire introuvable : $BIN_DIR"
    exit 1
fi
cp "$PROJECT_DIR/install.sh" "$BIN_DIR/"
# Création du zip

if [ ! -d "${PROJECT_DIR}/releases/" ]; then
    mkdir "${PROJECT_DIR}/releases"
fi

if [ ! -d "${PROJECT_DIR}/releases/version_$VERSION" ]; then
    mkdir "${PROJECT_DIR}/releases/version_$VERSION"
fi

ZIP_FILE="${PROJECT_DIR}/releases/version_$VERSION/celeneCLI_${TARGET}_${ARCH}.zip"

echo "📦 Compression du contenu de $BIN_DIR dans $ZIP_FILE ..."
cd "$BIN_DIR"
zip -r "$ZIP_FILE" ./*

echo "✅ Packaging terminé : $ZIP_FILE"