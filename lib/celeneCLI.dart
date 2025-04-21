

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
  // Initialisation de la classe DBManager pour récupérer les préférences utilisateur
  DBManager db = DBManager();

  // Reconstructions des attributs utilisés par l'objet CeleneParser et SecretManager pour les passer après aux classes concernées
  Map<String,dynamic> dbData = db.reconstruct();

  // Création de l'objet SecretManager
  // dbData["secureStorageStatus"] -> Indique si l'utilisateur à activé la persistance de session
  // dbData["credentialSaved"] -> Indique si l'utilisateur à enregistré ses logins CAS dans le trousseau
  SecretManager secrets = SecretManager(dbData["secureStorageStatus"],dbData["credentialSaved"], dbData["username"]);

  // Si SecretsManager ne trouve pas de login lors de la phase d'initialisation
  if (!secrets.getCredentialStatus()){
    // Alors on demande à l'utilisateur de donner ses identifiants
    (bool,String) credentials = await secrets.setCredentialsView();
    // Enregistrement des préférences utilisateurs si l'utilisateur à décidé d'enregistrer ses logins sur le trousseau.
    db.saveUserCredentialPreferences(credentials);
    db.saveUserSecureStoragePreferences(secrets.isSecureStorageSet());
  }

  SecureStorage? secureStorage;
  // initialisation de la classe CASAuth
  CASAuth cas = CASAuth();

  // Si l'utilisateur à activé la persistance de session
  if (dbData["secureStorageStatus"]){
    // Alors on crée/lit le stockage sécurisé

    // Création de l'objet SecureStorage en passant la clé de chiffrement en paramètre (secrets.getSecureStorageKey())
    secureStorage = SecureStorage(dbData["secureStorageStatus"], secrets.getSecureStorageKey(), secrets.getSecureStorageIV());

    // On fixe l'attribut secureStorage de la classe CASAuth à l'objet initialisé précédement;

    cas.setSecureStorage(secureStorage);
  }

  // Création de la classe CeleneParser en lui passant en paramètre les cours enregistré par l'utilisateur
  CeleneParser celene = CeleneParser(dbData["courses"]);
  // On passe les logins CAS à la classe pour se connecter à Celene ensuite
  celene.setCredentials(secrets.getCredentials());

  // On fixe l'attribut CAS à l'objet CAS crée précédemment
  celene.setCAS(cas);

  // On passe les fichiers téléchargés par l'utilisateur à la classe CeleneParser
  celene.files = dbData["files"];

  // Si aucune session n'as pu être chargée (soit pas de session, soit session trop vieille)
  if (!celene.loadCeleneSession()){
    // Alors on se connecte à celene
    print("No session detected, need to log in");
    // Lancement de la fonction loginToCelene() pour se connecter au CAS et créer une session Celene
    bool result = await celene.loginToCelene();

    // Si on a pas réussi à se connecter (Mauvais mdp ou mauvais login)
    if (!result){
      // TODO - Add better error handling
      print("ERROR while connecting to celene");
      throw Exception("Error while connecting to celene");
    }
  }

  print("Logged in to celene sucessuflly");
  // Initialisons de la page de sélection de cours (initialisation du controlleur et de la vue)
  ChooseCourseController ccController = ChooseCourseController(celene,db);
  ChooseCourseView ccView = ChooseCourseView(ccController);
  // On fixe la vue à afficher à celle de sélection de cours (ccView)
  navigator.setView(ccView);

  while (true){
    // Affichage à l'écran de la vue qui a été fixée avec navigator.setView();
    await navigator.display();
  }
}