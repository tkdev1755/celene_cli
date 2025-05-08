

import 'dart:io';

import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/controller/navigator.dart';
import 'package:celene_cli/model/DBManager.dart';
import 'package:celene_cli/model/celeneObject.dart';
import 'package:celene_cli/model/extensions.dart';
import 'package:celene_cli/model/secretManager.dart';
import 'package:celene_cli/model/secureStorage.dart';
import 'package:encrypt/encrypt.dart';

import '../celeneCLI.dart';
import '../view/view.dart';

class OptionsController extends Controller{
  CeleneParser celene;
  DBManager db;
  late SecretManager secretManager;
  late SecureStorage secureStorage;
  bool secStorageStatus = false;
  bool passwordStatus = false;
  List<(String,String)> settingsChoices = [
    ("Changer les identifiants", "changeID"),
    ("Désactiver la connexion automatique", "disableAutoConn"),
    ("Désactiver la persistance de session","disableCookiePersistance"),
    ("Réinitialiser le CLI","resetCLI"),
  ];
  OptionsController(this.celene, this.db){
    bool secStorageStatus = db.getSecureStorageStatus();
    bool userPrefStatus = db.getUserCredentialPreferences();
    String? username = db.getUsername();
    secretManager = SecretManager(secStorageStatus, userPrefStatus, username);
    if (secretManager.getSecureStorageStatus()){
      secStorageStatus = true;
      String password = secretManager.getSecureStorageKey()!;
      IV iv = secretManager.getSecureStorageIV()!;
      secureStorage = SecureStorage(true, password, iv);
    }
    passwordStatus = secretManager.getCredentialStatus();
  }


  @override
  getData() {
    logger("Getting data");
    if (!secretManager.getCredentialStatus()){
      settingsChoices[1] = ("Activer la connexion automatique","enableAutoConn");
      settingsChoices.removeAt(2);
      settingsChoices.removeAt(0);
    }
    else{
      logger("Password all set");
      if (!secretManager.getSecureStorageStatus()){
        logger("Password set but no session persistance");
        settingsChoices[2] = ("Activer la persistance de session","enableCookiePersistance");
      }
    }
    return settingsChoices;
  }

  @override
  bool getFlag(String flag) {
    if (flags.containsKey(flag)){
      return flags[flag]!;
    }
    else{
      throw Exception("Flag doesn't exists");
    }
  }

  @override
  handleInput(String type, data, {View? parent}) async{
    switch (type){
      case "exit":
        quitApp();
        break;
      case "changeID":
        await updateCredentials();
        break;
      case "enableAutoConn":
        return await updateCredentials();
      case "disableAutoConn":
        return deleteCredentials();
      case "disableCookiePersistance":
        return disableSecureStorage();
      case "enableCookiePersistance":
        return enableSessionPersistance();
      case "resetCLI":
        await resetCLI();
        break;
      case "return":
        getToPreviousPage();
        break;
    }
  }

  @override
  quitApp() {
    db.dumpChanges();
    Navigator.exitProgram();
  }

  @override
  setData(data) {
    throw UnimplementedError();
  }

  @override
  setFlag(String flag) {
    if (flags.containsKey(flag)){
      flags[flag] = !flags[flag]!;
    }
    else{
      throw Exception("Trying to set a non existant flag");
    }
  }
  getToPreviousPage(){
    navigator.pop();
  }

  resetCLI() async {
    print("Êtes-vous sur de vouloir tout supprimer (Cours,Préférences) ? (y/n)");
    String resetCLIStr = stdin.readLineSync() ?? "n";
    bool resetCLIStatus = (resetCLIStr.toUpperCase() == "Y" || resetCLIStr.toUpperCase() == "YES" || resetCLIStr.toUpperCase() == "OUI");
    if (resetCLIStatus){
      print("Supression des préférences utilisateur");
      db.clearDB();
      secretManager.deleteUserCredentials();
      secretManager.deleteSecureStorageCredentials();
      if (secretManager.getSecureStorageStatus()){
        secureStorage.clearSecureStorage();
      }
      print("Suppression des cours téléchargés");
      for (Classes i in celene.courses){
        Directory courseDir = Directory("$BASEDIR/${i.celeneID}");
        print("Deleting ${i.name} |${i.celeneID}");
        await courseDir.delete(recursive: true);
        print("Deleted ${i.name} |${i.celeneID}");

      }
      celene.courses.clear();
      celene.files.clear();
      celene.loggedIn = false;
      print("Fermeture du programme pour prendre en compte les changements");
      await quitApp();
    }


  }
  enableAutoConn() async {
    (bool, String) res = await secretManager.setCredentialsView();

  }
  enableSessionPersistance() async{
    secretManager.setSecureStorage();
    db.saveUserSecureStoragePreferences(secretManager.isSecureStorageSet());
    //secureStorage = SecureStorage(secretManager.isSecureStorageSet(), secretManager.getSecureStorageKey(), secretManager.getSecureStorageIV());
    return !secretManager.isSecureStorageSet();
  }
  updateCredentials() async {
    return !((await secretManager.updateUserCredentialsView())).$1;
  }

  deleteCredentials() async {
    bool res = secretManager.deleteUserCredentials();
    logger("Deleted user credentials - $res, secretsStatus ${secretManager.getCredentialStatus()}");
    res = secretManager.deleteSecureStorageCredentials();
    logger("Deleted SecureStorage credentials - $res, secStorageStat ${secretManager.getSecureStorageStatus()}");
    res= (await secureStorage.clearSecureStorage()) == 0;
    logger("Deleted SecureStorage credentials - $res");
    db.saveUserCredentialPreferences((false, ""));
    db.saveUserSecureStoragePreferences(false);
    // Returns false to force the view to refresh, so it takes in account the status
    return false;
  }
  disableSecureStorage(){
    bool res =  secretManager.deleteSecureStorageCredentials();
    logger("Deleted SecureStorage credentials - $res, secStorage status ${secretManager.getSecureStorageStatus()}");
    secureStorage.clearSecureStorage();
    db.saveUserSecureStoragePreferences(false);
    return false;
  }
}