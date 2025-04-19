#!/bin/bash

C_BIN=libkeychain.dylib
DART_BIN=celene_cli.exe
WORK_DIR=/celene_cli
LIB_DIR=lib/model/KeychainAPI/linux
BIN_DIR=bin/celeneCli_linux_x64


if [ -d $WORK_DIR ]; then
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


