# Celene_CLI

# Quel est le but de cette app ?

- Permettre d’accéder à la plateforme de E-Learning celene sans passer par le site web.
- Gérer les différentes ressources téléchargées sur cette plateforme et éviter d’à chaque fois re-télécharger des fichiers parce qu’on ne sait plus où ils sont

# Quelles fonctionnalités ?

## Fonctionnalités implémentée

✅ - Connexion automatique au CAS

✅ - Ajout des cours sur Celene manuellement à travers les URL de ces derniers

✅ - Téléchargement des fichier/dossiers présents sur la page Celene d'un cours et ouverture des fichiers si déjà téléchargés

✅ - Persistance des sessions d'une instance du programme à l'autre (limitée dans le temps)

✅ - Portabilité de l'outil (fonctionne sur GNU/Linux, MacOS et Windows)

## Fonctionnalité à venir

> Ces fonctionnalité sont classées par ordre de priorité (🟥 : Important, implémentation prochaine, 🟨: Moyennement important, implémentation une fois les fct importantes implémentées)

🟥 - Import des cours automatiques à partir du profil utilisateur Celene

🟥 - Pouvoir réinitialiser depuis le CLI les préférences utilisateur

🟥 - Implémentations des fonctionnalités de modification et de suppressions des credentials au niveau des trousseaux systèmes (expliqué plus bas)

🟨 - Optimisations au niveau de l'usage de la ram (C'est pas très fameux en ce moment)

N’hésitez pas à proposer des fonctionnalités si vous avez des idées, et même contribuer en faisant des pull requests

# Fonctionnement  de la connexion automatique et persistance de session

- Lorsque vous acceptez d’enregistrer vos logins CAS lors de la première ouverture du programme ces derniers ne quittent jamais votre appareil et sont enregistrés de manière sécurisée. Les information de connexion sont enregistrées dans le "trousseau de clés" de votre système d’exploitation (`Keychain` pour MacOS, `Windows Credential Manager` pour Windows, et `GNOME-Secret` pour GNU/Linux) et sont lus au démarrage du programme pour pouvoir vous connecter automatiquement au CAS. Le programme ne lit aucune autre entrée du trousseau de clés et une attention particulière a été faite pour que les fonctions ne soient pas accessibles n'importe où à n'importe quel moment.
- En ce qui concerne la persistance de session, les données de session sont stockées dans un fichier chiffré à l’aide d’un mot de passe généré aléatoirement pour chaque utilisateur qui lance le programme. Ce même mot de passe est stocké dans le trousseau de clé de votre système d’exploitation et n’est visible dans ce dit trousseau que si vous entrez le mot de passe de votre session

> Si cela n’est pas assez sécurisé à votre goût, vous pouvez toujours ne pas enregistrer vos informations de connexion et ne pas enregistrer vos données de sessions en répondant « no » ou « n » lorsqu’on vous pose la question au démarrage du programme

> J’ai essayé de prendre toutes les précautions possibles lorsqu’il s’agit de "sécuriser" ces données sensibles, cependant, de par mon manque d’expérience, je ne pense pas avoir la meilleure implémentation et suis à l’écoute de tout conseil visant à améliorer la sécurisation de ces données

# Comment utiliser celene_cli

## Installation

- Afin d’installer le logiciel, vous devez tout d’abord télécharger le binaire depuis la page Release de ce repo git en fonction de votre système d’exploitation
- Une fois le binaire téléchargé. Dézippez le fichier zip et lancez le script `install.sh` (Linux&MacOS) ou `install.ps1` (Windows)
    - Ce script va déplacer le binaire et les fichiers associés à celui-ci vers votre dossier utilisateur dans le dossier celeneCLI, c’est ici que vous retrouverez les fichiers téléchargés par le programme et l’index des cours
    - Il ajoutera ensuite le binaire à votre PATH pour que vous puissiez l’appeler depuis votre terminal , par défaut le script l’ajoute sous le nom de « celene », vous pouvez changer ce nom dans le script avec la variable $celene_cli_name
- Maintenant vous pouvez utiliser le programme depuis votre terminal

# Questions fréquentes

- > Pourquoi il y’a des fichiers `.dll`, `.dylib`, `.so` avec le binaire ?
    - >> Le langage de programmation utilisé (Dart) ne possède pas de librairie donnant accès au trousseau de clé du système d’exploitation, par conséquent j’ai du développer une "librairie" en C pour interagir avec le trousseau de clés, plus de détail sont donnés dans le wiki. Tout le code source de la « librairie » C est disponible sur le github dans le dossier lib/model/KeychainAPI/${votre_système_d’exploitation}/${votre_système_d’exploitation}keychainAPI.c

----

- > Pourquoi avoir développé en Dart et pas en python ?
    - >> En majeure partie parce que c’est le langage que je maitrise le mieux et puis que je le trouvais le plus approprié pour développer ce genre d’outil. Cependant je peux comprendre pourquoi python peut être plus intéressant sur certains points (plus de librairies disponibles, connu de tous, et performances correctes)
    - >> Également cela m’as permis de réutiliser le code développé intégralement dans le GUI que j’ai développé à l’aide du framework Flutter au lieu de devoir réécrire toute la logique de connexion pour le GUI









