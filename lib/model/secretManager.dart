
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:celene_cli/model/KeychainAPI/keyring.dart';
import 'package:dart_console/dart_console.dart';
import 'package:encrypt/encrypt.dart';
import 'package:uuid/uuid.dart';
import 'extensions.dart';

/// {@category SAFETY}
/// Classe stockant les informations confidentielles de l'utilisateur
class SecretManager{
  /// login CAS de l'utilisateur (si sauvegardé)
  String? _login;
  /// Mot de passe CAS de l'utilisateur (si sauvegardé)
  String? _password;
  /// Indique si les informations de connexion ont été sauvegardé
  bool _credentialSaved;
  /// Indique si le SecureStorage est activé (Persistance de session activée)
  bool _secureStorageSet;
  /// Clé de déchiffrement du SecureStorage (si activé)
  String? _secureStorageKey;
  /// IV de déchiffrement du SecureStorage (si activé)
  String? _secureStorageIV;
  /// Indique si les informations de connexion ont pu être chargée correctement
  bool _credentialLoaded = false;
  /// Indique si les informations de déchiffrement du SecureStorage ont pu être chargées correctement
  bool _secureStorageLoaded = false;

  /// Objet permettant d'intéragir avec le trousseau de clé du système
  final Keyring _keyring = Keyring();

  /// Nom de service utilisé pour l'enregistrement des informations de connexion de l'utilisateur
  final String _SERVICE_NAME = "celeneManager";
  /// Nom de service utilisé pour l'enregistrement des informations de déchiffrement du SecureStorage
  final String _SECURE_SERVICE_NAME = "celeneManagerSecureStorage";
  /// Nom d'utilisateur utilisé pour l'enregistrement des informations de déchiffrement du SecureStorage
  final String _SECURE_SERVICE_USERNAME = "cmssUser";
  /// Nom de service utilisé pour l'enregistrement des informations de déchiffrement du SecureStorage (IV)
  final String _SECURE_SERVICE_IVNAME = "celeneManagerSecureStorageIV";
  /// Nom d'utilisateur utilisé pour l'enregistrement des informations de déchiffrement du SecureStorage (IV)
  final String _SECURE_SERVICE_IVUSERNAME = "cmssIVUser";

  SecretManager(this._secureStorageSet, this._credentialSaved,this._login){
    if (_credentialSaved){
      if (_login == null){
        throw Exception("Credential should be saved on disk but username is null");
      }
      _password = _keyring.getPassword(_SERVICE_NAME, _login!);
      _credentialLoaded = _password != null;
    }
    if (_secureStorageSet){
      _secureStorageKey = _keyring.getPassword(_SECURE_SERVICE_NAME, _SECURE_SERVICE_USERNAME);
      _secureStorageIV = _keyring.getPassword(_SECURE_SERVICE_IVNAME, _SECURE_SERVICE_IVUSERNAME);
      _secureStorageLoaded = _secureStorageKey != null && _secureStorageIV != null;
    }
  }
  /// Fonction permettant de récupérer les informations de connexion CAS
  (String,String) getCredentials(){
    if (_credentialLoaded){
      return (_login!,_password!);
    }
    else{
      throw Exception("Credential aren't loaded");
    }
  }
  /// Fonction permettant de fixer les informations de connexion CAS
  /// Par défaut elle ne sont pas enregistrée dans le trousseau de clé du système
  bool setCredentials(String username, String password,{bool saveToKeyring=false}){
    _login = username;
    _password = password;
    _credentialLoaded = true;
    logger(_password);
    if (saveToKeyring){
      if (username.length > 2048){
        logger("Username too big, aborting");
        throw ArgumentError.value(username.length, "Username too long, not saving it for security purposes");
      }
      if (password.length > 2048){
        logger("Password too long, aborting");
        throw ArgumentError.value("password too long, not saving it for security purposes");
      }
      int result = _keyring.setPassword(_SERVICE_NAME, _login!, _password!);

      return result == 0;
    }
    return false;
  }
  /// Fonction permettant d'obtenir le status de lecture des informations de connexion CAS.
  /// Vrai si les informations ont été chargées, faux sinon
  getCredentialStatus(){
    return _credentialLoaded;
  }
  /// Fonction permettant d'obtenir le status de lecture des informations de chiffrement du Secure Storage.
  /// Vrai si les informations ont été chargées, faux sinon
  getSecureStorageStatus(){
    return _secureStorageLoaded;
  }

  /// Fonction permettant d'obtenir la clé de déchiffrement du SecureStorage
  /// retourne null si la clé n'existe pas
  String? getSecureStorageKey(){
    if (_secureStorageLoaded){
      return _secureStorageKey;
    }
    else{
      return null;
    }
  }
  /// Fonction permettant d'obtenir la clé de déchiffrement (IV) du SecureStorage
  /// retourne null si la clé n'existe pas
  IV? getSecureStorageIV(){
    if  (_secureStorageLoaded){
      return IV.fromBase64(_secureStorageIV!);
    }
    else{
      return null;
    }
  }

  /// Fonction créant les clés de chiffrement du secureStorage
  /// retourne False si l'une des deux étapes à échoué
  bool setSecureStorage(){
    bool secureStorageKeyStatus = setSecureStorageKey();
    bool secureStorageIVStatus = setSecureStorageIV();
    _secureStorageSet = secureStorageIVStatus && secureStorageKeyStatus;
    return _secureStorageSet;
  }

  /// Permet de savoir si le secureStorage (Persistance de session) est activée par l'utilisateur
  isSecureStorageSet(){
    return _secureStorageSet;
  }

  /// Fonction créant la clé de chiffrement aléatoire du SecureStorage
  bool setSecureStorageKey(){
    String key = Uuid().v4().substring(0,16);
    int result = _keyring.setPassword(_SECURE_SERVICE_NAME, _SECURE_SERVICE_USERNAME, key);
    if (result == 0){
      _secureStorageKey = key;
    }
    return result == 0;
  }
  /// Fonction créant la clé de chiffrement aléatoire (IV) du SecureStorage
  bool setSecureStorageIV(){
    IV iv = IV.fromLength(16);
    int result = _keyring.setPassword(_SECURE_SERVICE_IVNAME, _SECURE_SERVICE_IVUSERNAME, iv.base64);
    if (result == 0){
      _secureStorageIV = iv.base64;
    }
    return result == 0;
  }

  /// Vue permettant de demander à l'utilisateur d'entrer ses informations de connexion
  Future<(bool,String)> setCredentialsView() async {
    final Console console = Console();
    String userName = "";
    String password = "";
    console.writeLine('=== Entrez vos identifiants CAS ===\n');
    console.write("Nom d'utilisateur : ");
    userName = stdin.readLineSync() ?? "";
    console.write('\n');
    console.write('Mot de passe : ');
    password = await getSecureEntry();
    console.write('\n');
    console.write("Mot de passe iiiiiis $password\n");
    console.write('Sauvergarder pour la prochaine fois ? (Y(es)/n) : ');
    String stringSaveCredentials = stdin.readLineSync() ?? "n";
    console.write('\n');
    bool saveCredentials = (stringSaveCredentials.toUpperCase() == "Y" || stringSaveCredentials.toUpperCase() == "YES" || stringSaveCredentials.toUpperCase() == "OUI");
    console.write('Activer les sessions persistantes (Session CAS gardée d\'un lancement de programme à l\'autre) ?');
    String stringActivateSecureStorage = stdin.readLineSync() ?? "n";
    bool activateSecureStorage = (stringSaveCredentials.toUpperCase() == "Y" || stringSaveCredentials.toUpperCase() == "YES" || stringSaveCredentials.toUpperCase() == "OUI");
    logger("Saving credentials ? :$saveCredentials");
    bool credResult = setCredentials(userName, password, saveToKeyring: saveCredentials);
    bool secureStorageResult = false;
    if (activateSecureStorage){
      secureStorageResult = setSecureStorage();
    }
    logger("Credential save result :$credResult");
    logger("Secure storage save result $secureStorageResult");
    return (credResult && saveCredentials, userName);
  }

  /// Fonction permettant de cacher le résultat de l'entrée standard à l'écran, utilisé lorsqu'un mot de passe est demandé ?
  Future<String> getSecureEntry({String prompt = '> '}) async {
    // Dumb function to cover dart lack of secure keyboard entry capabilities (doesn't logger stdin to the screen when the secure entry is written by the user)
    // Doesn't work on windows for some weird reason
    if (!Platform.isWindows){
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
    stdout.write(prompt);
    final buffer = <int>[];
    final completer = Completer<String>();
    String pass = stdin.readLineSync() ?? "";
    if (!Platform.isWindows){
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
    return pass;
  }

}