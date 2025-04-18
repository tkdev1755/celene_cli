

import 'package:celene_cli/controller/chooseCourseController.dart';
import 'package:celene_cli/model/DBManager.dart';
import 'package:celene_cli/model/celeneObject.dart';
import 'package:celene_cli/model/secureStorage.dart';
import 'package:celene_cli/view/chooseCourseView.dart';
import 'package:encrypt/encrypt.dart';

import '../model/casAuthentification.dart';
import '../model/secretManager.dart';
import 'controller/navigator.dart';

Navigator navigator = Navigator();
Future<int> main() async{
  DBManager db = DBManager();
  Map<String,dynamic> dbData = db.reconstruct();
  SecretManager secrets = SecretManager(dbData["secureStorageStatus"],dbData["credentialSaved"], dbData["username"]);
  if (!secrets.getCredentialStatus()){
    print("Credentials are not set, so we need to ask the user for credentials");
    (bool,String) credentials = await secrets.setCredentialsView();
    db.saveUserCredentialPreferences(credentials);
    db.saveUserSecureStoragePreferences(secrets.isSecureStorageSet());
  }
  SecureStorage? secureStorage;
  CASAuth cas = CASAuth();
  if (dbData["secureStorageStatus"]){
    secureStorage = SecureStorage(dbData["secureStorageStatus"], secrets.getSecureStorageKey(), secrets.getSecureStorageIV());
    cas.setSecureStorage(secureStorage);
  }
  CeleneParser celene = CeleneParser(dbData["courses"]);
  celene.setCredentials(secrets.getCredentials());
  celene.setCAS(cas);
  celene.files = dbData["files"];
  if (!celene.loadCeleneSession()){
    print("No session detected, need to log in");
    bool result = await celene.loginToCelene();
    if (!result){
      print("ERROR while connecting to celene");
      throw Exception("Errow");
    }
  }
  print("Logged in sucessuflly");
  ChooseCourseController ccController = ChooseCourseController(celene,db);
  ChooseCourseView ccView = ChooseCourseView(ccController);

  navigator.setView(ccView);
  while (true){
    await navigator.display();
  }
}