
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:celene_cli/model/KeychainAPI/keyring.dart';
import 'package:dart_console/dart_console.dart';
import 'package:encrypt/encrypt.dart';
import 'package:uuid/uuid.dart';
import 'extensions.dart';

class SecretManager{

  String? _login;
  String? _password;
  bool _credentialSaved;
  bool _secureStorageSet;
  String? _secureStorageKey;
  String? _secureStorageIV;
  bool _credentialLoaded = false;
  bool _secureStorageLoaded = false;
  final Keyring _keyring = Keyring();
  final String _SERVICE_NAME = "celeneManager";
  final String _SECURE_SERVICE_NAME = "celeneManagerSecureStorage";
  final String _SECURE_SERVICE_USERNAME = "cmssUser";
  final String _SECURE_SERVICE_IVNAME = "celeneManagerSecureStorageIV";
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

  (String,String) getCredentials(){
    if (_credentialLoaded){
      return (_login!,_password!);
    }
    else{
      throw Exception("Credential aren't loaded");
    }
  }

  bool setCredentials(String username, String password,{bool saveToKeyring=false}){
    _login = username;
    _password = password;
    _credentialLoaded = true;
    print(_password);
    if (saveToKeyring){
      if (username.length > 2048){
        print("Username too big, aborting");
        throw ArgumentError.value(username.length, "Username too long, not saving it for security purposes");
      }
      if (password.length > 2048){
        print("Password too long, aborting");
        throw ArgumentError.value("password too long, not saving it for security purposes");
      }
      int result = _keyring.setPassword(_SERVICE_NAME, _login!, _password!);

      return result == 0;
    }
    return false;
  }

  getCredentialStatus(){
    return _credentialLoaded;
  }

  getSecureStorageStatus(){
    return _secureStorageLoaded;
  }

  String? getSecureStorageKey(){
    if (_secureStorageLoaded){
      return _secureStorageKey;
    }
    else{
      return null;
    }
  }
  IV? getSecureStorageIV(){
    if  (_secureStorageLoaded){
      return IV.fromBase64(_secureStorageIV!);
    }
    else{
      return null;
    }
  }

  bool setSecureStorage(){
    bool secureStorageKeyStatus = setSecureStorageKey();
    bool secureStorageIVStatus = setSecureStorageIV();
    _secureStorageSet = secureStorageIVStatus && secureStorageKeyStatus;
    return _secureStorageSet;
  }

  isSecureStorageSet(){
    return _secureStorageSet;
  }


  bool setSecureStorageKey(){
    String key = Uuid().v4().substring(0,16);
    int result = _keyring.setPassword(_SECURE_SERVICE_NAME, _SECURE_SERVICE_USERNAME, key);
    if (result == 0){
      _secureStorageKey = key;
    }
    return result == 0;
  }

  bool setSecureStorageIV(){
    IV iv = IV.fromLength(16);
    int result = _keyring.setPassword(_SECURE_SERVICE_IVNAME, _SECURE_SERVICE_IVUSERNAME, iv.base64);
    if (result == 0){
      _secureStorageIV = iv.base64;
    }
    return result == 0;
  }

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
    print("Saving credentials ? :$saveCredentials");
    bool credResult = setCredentials(userName, password, saveToKeyring: saveCredentials);
    bool secureStorageResult = setSecureStorage();
    print("Credential save result :$credResult");
    print("Secure storage save result $secureStorageResult");
    return (credResult && saveCredentials, userName);
  }

  Future<String> getSecureEntry({String prompt = '> '}) async {
    // Dumb function to cover dart lack of secure keyboard entry capabilities (doesn't print stdin to the screen when the secure entry is written by the user)
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