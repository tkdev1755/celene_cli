#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "❌ Utilisation : $0 <ARCH>"
    exit 1
fi
ARCH=$1
C_BIN=libkeychain.dylib
DART_BIN=celene_cli
WORK_DIR=$CELENE_CLI_PROJROOT
LIB_DIR=lib/model/KeychainAPI/macos
BIN_DIR=bin/celeneCli_macOS_$ARCH

if [ -d "$WORK_DIR" ]; then
      cd "$WORK_DIR" || { echo "Erreur : Impossible d'accéder au dossier $WORK_DIR."; exit 1; }
fi
echo "Compilation du binaire DART";
dart pub get
dart compile exe bin/celene_cli.dart
if [ $? -ne 0 ]; then
  echo "Error while compiling the dart exec"
  exit 1
fi
mv bin/celene_cli.exe bin/celene_cli
if [ -d $LIB_DIR ]; then
      cd "$LIB_DIR" || { echo "Erreur : Impossible d'accéder au dossier $LIB_DIR."; exit 1; }
fi
make
if [ $? -ne 0 ]; then
  echo "Error while compiling the C BIN"
  exit 1
fi
if [ -d $BIN_DIR ]
then
      cp "$C_BIN" "$BIN_DIR/" || { echo "Erreur : Impossible de copier le binaire C depuis $LIB_DIR."; exit 1; }
      cp "$WORK_DIR/bin/$DART_BIN" BIN_DIR/ || { echo "Erreur : Impossible de copier le binaire dart depuis bin."; exit 1; }
else
    cd "$WORK_DIR" || { echo "Erreur : Impossible d'accéder au dossier $WORK_DIR."; exit 1; }
    mkdir "$BIN_DIR"
    cd "$LIB_DIR" || { echo "Erreur : Impossible d'accéder au dossier $LIB_DIR."; exit 1; }
    cp "$C_BIN" "$WORK_DIR/$BIN_DIR/" || { echo "Erreur : Impossible de copier le binaire C depuis $LIB_DIR."; exit 1; }
    cp "$WORK_DIR/bin/$DART_BIN" "$WORK_DIR/$BIN_DIR/" || { echo "Erreur : Impossible de copier le binaire dart depuis bin."; exit 1; }
fi


