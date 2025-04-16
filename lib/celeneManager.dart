

import 'package:celene_cli/controller/chooseCourseController.dart';
import 'package:celene_cli/model/DBManager.dart';
import 'package:celene_cli/model/celeneObject.dart';
import 'package:celene_cli/view/chooseCourseView.dart';

import '../model/casAuthentification.dart';
import '../model/secretManager.dart';
import 'controller/navigator.dart';

Navigator navigator = Navigator();
Future<int> main() async{
  DBManager db = DBManager();
  Map<String,dynamic> dbData = db.reconstruct();
  SecretManager secrets = SecretManager(dbData["credentialSaved"], dbData["username"]);
  if (!secrets.getCredentialStatus()){
    print("Credentials are not set, so we need to ask the user for credentials");
    (bool,String) credentials = await secrets.setCredentialsView();
    db.saveUserCredentialPreferences(credentials);
  }

  (String,String) creds = secrets.getCredentials();
  CASAuth cas = CASAuth();
  CeleneParser celene = CeleneParser(dbData["courses"]);
  celene.setCredentials(creds);
  creds = ("","");
  celene.files = dbData["files"];
  if (!celene.loadCeleneSession()){
    print("No session detected, need to log in");
    bool result = await celene.loginToCelene();
    if (!result){
      print("ERROR while connecting to celene");
      throw Exception("Errow ");
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