#!/bin/bash

set -e  # Arrêter le script en cas d'erreur

APP_NAME="celene_cli"
INSTALL_DIR="$HOME/celeneCLI"
celene_cli_name="celene"
# Détection du système
OS="$(uname)"
if [[ "$OS" == "Darwin" ]]; then
    LIB_FILE="libkeychain.dylib"
elif [[ "$OS" == "Linux" ]]; then
    LIB_FILE="libkeychain.so"
else
    echo "❌ Système non supporté : $OS"
    exit 1
fi

# Création du dossier d'installation
if [ ! -d $INSTALL_DIR ]; then
  mkdir -p "$INSTALL_DIR"
fi

# Copie des fichiers
cp "$APP_NAME" "$INSTALL_DIR/"
cp "$LIB_FILE" "$INSTALL_DIR/"

# Détection du fichier de configuration du shell
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
else
    echo "Configuration shell inconnue"
    exit 1
fi

echo "Fichier de configuration détecté : $SHELL_RC (Shell : $SHELL_NAME)"
# Ajout de l'alias si pas encore présent
if grep -q "alias $celene_cli_name=" "$SHELL_RC"; then
    echo "Alias '$celene_cli_name' déjà existant dans $SHELL_RC. Aucune modification n'as été apportée"
else
    echo "Ajout de l'alias dans $SHELL_RC..."
    echo "" >> "$SHELL_RC"
    echo "# Alias celene_cli" >> "$SHELL_RC"
      echo "alias $celene_cli_name=\"$INSTALL_DIR/$APP_NAME\"" >> "$SHELL_RC"
    echo "Alias ajouté !"
fi

echo ""
echo "👉 Rechargez votre shell en tapant la commande : source $SHELL_RC"
echo "   Ou redémarrez votre terminal."
