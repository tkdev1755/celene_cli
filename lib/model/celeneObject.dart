
import 'dart:convert';
import 'dart:io';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:celene_cli/model/casAuthentification.dart';
import 'package:celene_cli/model/fileManager.dart';
import 'package:http/http.dart';
import 'extensions.dart';
import 'package:uuid/uuid.dart';

/// {@category API-WEB}
/// /// {@subCategory API Celene}
/// Classe permettant d'intéragir avec la plateforme Celene
class CeleneParser{

  /// Mot de passe et login pour se connecter
  late final (String,String)? _credentials;
  /// Objet CASAuth pour créer une session celene
  CASAuth? _casAuth;
  /// Indique l'état de la session actuelle
  bool loggedIn = false;

  /// Liste des cours enregistrés par l'utilisateur
  List<Classes> courses;
  /// Dictionnaire des fichiers téléchargés par l'utilisateur
  Map<String,List<FileEntry>> files = {};
  /// URL pointant sur la plateforme Celene
  String celeneEndpoint = "https://celene.insa-cvl.fr";
  CeleneParser(
      this.courses
      );

  /// Permet d'obtenir l'URL d'un cours sur celene à partir de l'ID
  Uri getClassUrl(cID){
    String url = "$celeneEndpoint/course/view.php?id=${cID}";
    return Uri.parse(url);
  }
  /// Permet d'obtenir l'URL de téléchargement d'un dossier sur celene à partir de son ID
  Uri getFolderDownloadLink(id){
    String url = "$celeneEndpoint/mod/folder/download_folder.php?id=${id}";
    return Uri.parse(url);
  }

  /// Permet d'obtenir l'ID d'un cours sur celene à partir de l'URL
  static int getIDFromUrl(String url){
    Map<String,String>  params = Uri.parse(url).queryParameters;
    if (!params.containsKey("id")){
      return -1;
    }
    return int.parse(params["id"]!);
  }

  /// Initialise l'attribut credentials à la valeur passée en paramètre
  void setCredentials((String,String) credentials){
    _credentials = credentials;
  }

  /// Initialise l'attribut casAuth à la valeur passée en paramètre
  void setCAS(CASAuth cas){
    _casAuth = cas;
  }
  /// Fonction pour se connecter à celene et créer une session
  Future<bool> loginToCelene() async{
    if (_credentials == null){
      print("CREDENTIAL NULL SO DOING NOTHING");
      throw Exception("Credentials didn't exist at the time of creation");
    }
    print("creds are $_credentials");
    _casAuth ??= CASAuth();

    try{

    }
    on Exception{
      print("Exception while connecting to CAS");
      loggedIn = false;
      return false;
    }

    int casResult = await _casAuth!.loginToCas(_credentials[0], _credentials[1], "Celene");
    if (casResult == -1){
      return false;
    }

    _casAuth!.sessionDate = DateTime.now();
    loggedIn = true;
    await saveCeleneSession();
    return true;
  }
  /// Sauvegarde la session Celene si la persistance de session est activée
  Future<bool> saveCeleneSession() async {
    _casAuth ??= CASAuth();

    bool saveResult = await _casAuth!.saveCASSession([("MoodleSession","moodleSession"),("MOODLEID1_","moodleID")]);
    /*if (casAuth !=null){
      print("Saving session NOW !");
      if (casAuth!.secureStorage.get("casCookies") != null){
       casAuth!.secureStorage.clear();
      }
      Map<String,Map<String,String>> sessionCookies = {};
      Map<String,dynamic> saveData = {
        "cookies" : sessionCookies,
        "sessionDate" :  DateFormat("dd-MM-yyyy-HH:mm").format((casAuth!.sessionDate ?? DateTime.now()))
      };
      for (int i = 0; i<casAuth!.session.cookieStore.cookies.length; i++){
        cStore.Cookie cookie = casAuth!.session.cookieStore.cookies[i];

        sessionCookies[cookie.name] = {
          "value" : cookie.value,
          "path" : cookie.path,
          "domain" : cookie.domain,
          "expires" : DateFormat("dd-MM-yyyy-HH:mm:ss").format(cookie.expiryTime ?? DateTime.now().add(Duration(minutes: 10)))
        };
      }
      casAuth!.secureStorage.write(saveData, "casCookies");
      print(casAuth!.secureStorage.get("casCookies")?.value);
    }*/
    return saveResult;
  }

  /// Charge la session celene si la persistance de session à été activée
  /// Retourne vrai si la session a été chargée correctement, faux autrement
  bool loadCeleneSession(){
    _casAuth ??= CASAuth();

    // The tuple represents $1-> name of the value stored in secure storage ; $2 -> name of the cookie in the cookiejar ; $3 -> url of the cookie
    bool result = _casAuth!.loadCASSession([("moodleID","MOODLEID1_","https://celene.insa-cvl.fr/"), ("moodleSession","MoodleSession","https://celene.insa-cvl.fr")]);
    loggedIn = result;
    /*if (sessionValue == null){
      print("Nothing to load h ere");
      return false;
    }
    print("We do have a value");
    Map<String,dynamic> cookies = sessionValue.value;
    print("Here is the value -> $cookies");
    DateTime sessionDate = DateFormat("dd-MM-yyyy/HH:mm:ss").parse(cookies["sessionDate"]);
    print("Sessions delta is ${DateTime.now().difference(sessionDate).inMinutes}");
    if (DateTime.now().difference(sessionDate).inMinutes > 30){
      print("Session too old, creating a new session");
      return false;
    }
    cookies.forEach((k,v){
      cStore.Cookie newCookie = cStore.Cookie(
        v["name"]!,
        v["value"]!,
      );
      newCookie.domain = v["domain"]!;
      newCookie.path = v["path"]!;
      casAuth!.session.cookieStore.cookies.add(newCookie);
    });
    print("Added successfully ${cookies.length}");*/
    return result;
  }
  /// Récupère et lit la page d'un cours sur celene, retourne la liste des ressources disponibles sur cette page
  Future<List<Course>> getClassData(cID,classID) async{
    List<FileEntry> downloadedCourse = files.containsKey(classID) ? files[classID]! : [];
    print(files);
    print("Loaded downloaded courses");
    List<Course> courses = [];
    if (!loggedIn){
      print("Not logged in, need to log in to Celene");
      bool result = await loginToCelene();
      if (!result){
        throw Exception("ERROR WHILE CONNECTING TO CELENE");
      }

      print("Successfully logged in to Celene");
    }
    print(_casAuth?.session.cookieStore.cookies);
    if (_casAuth != null){
      Uri classUrl = getClassUrl(cID);
      print("Now retrieving class data : class url is ${classUrl}");
      //casAuth!.prepareRequest();
      print("CAS AUTH HEADERS");
      Response classData;
      try{
        classData = await _casAuth!.session.get(classUrl, headers: _casAuth!.headers);
      }
      on ClientException{
        classData = await _casAuth!.session.get(classUrl, headers: _casAuth!.headers);
      }
      print("Get response finished");
      if (classData.statusCode == 200){
        print("GET RESPONSE 200 -> Now parsing the page");
        //casAuth!.session.updateCookies(classData);
        //casAuth!.prepareRequest();
        BeautifulSoup soup = BeautifulSoup(classData.body);
        //print(soup.prettify());
        List<Bs4Element> li_elements = soup.findAll("li", class_:"activity activity-wrapper");
        print("Found ${li_elements.length} li_elements");
        for (Bs4Element i in li_elements){
          Course? newCourse = Course.constructFromCeleneInfo(i);
          if (newCourse != null){
            FileEntry? associatedFile = downloadedCourse.where((e) => e.entryName == newCourse.name).toList().firstOrNull;
            print(associatedFile);
            newCourse.downloaded = associatedFile != null;
            newCourse.associatedFile = associatedFile;
            if (newCourse.type == "Dossier" && newCourse.downloaded){
              print("The folder is downloaded so we have to add all files in this folder");
              for (FileEntry j in (newCourse.associatedFile!.children)!){
                print("Adding subCourse");
                Course subCourse = Course.constructFromFileInfo(j);
                subCourse.setFile(j);
                courses.add(subCourse);
              }
            }
            else{
              courses.add(newCourse);
            }
          }
        }
      }
      return courses;
    }
    return courses;
  }

  /// Téléchage un fichier disponible sur celene
  Future<String> _downloadFile(String link,savePath) async {
    if (!loggedIn){
      loginToCelene();
    }
    print("Now Downloading file");
    Uri uri = Uri.parse(link);
    print("Sending GET to ${uri}");
    int tries = 0;
    Response downloadResponse;
    try {
      downloadResponse = await _casAuth!.session.get(uri,headers: _casAuth!.headers);
    }
    on ClientException {
      downloadResponse = await _casAuth!.session.get(uri,headers: _casAuth!.headers);
      tries++;
    }
    if (downloadResponse.statusCode == 200){
      print("Successfully downloaded the file");
      String filename = "unknownFile";
      print(downloadResponse.headers);
      String? contentDisposition = downloadResponse.headers["content-disposition"];
      if (contentDisposition !=  null){
        print("Content disposition is not null so we may have a filename");
        String filename = contentDisposition.split(";")[1];
        print("filename length ${filename.length}");
        filename = filename.substring(11, filename.length-1);
        filename = utf8.decode(latin1.encode(filename));
        print("Filename is $filename");
        File downloadedFile = File("$BASEDIR$savePath/$filename");
        downloadedFile.createSync(recursive: true);
        await downloadedFile.writeAsBytes(downloadResponse.bodyBytes);
        print("File downloaded and saved on disk");
        return filename;
      }
      else{
        return "";

      }

    }
    else{
      print("Error while trying to download the file, ${downloadResponse.statusCode} |${downloadResponse.reasonPhrase}");
      print("${downloadResponse.body} \n ${downloadResponse.headers}");
      return "";
    }
  }

  /// Télécharge un dossier disponible sur celene
  Future<String> _downloadFolder(String link,String savePath) async {
    print("Downloading folder");
    int objID = getIDFromUrl(link);
    Uri dlLink = getFolderDownloadLink(objID);
    if (!loggedIn){
      loginToCelene();
    }
    print("Now sending data");
    Response dlResponse;
    try {
      dlResponse = await _casAuth!.session.get(dlLink, headers: _casAuth!.headers);
    }
    on ClientException{
      dlResponse = await _casAuth!.session.get(dlLink, headers: _casAuth!.headers);
    }
    print("Recieved data");
    if (dlResponse.statusCode == 200){
      print("File Download successful");
      String filename = "UnknownFile";
      String? contentDisposition = dlResponse.headers["content-disposition"];
      if (contentDisposition !=  null){
        String filename = contentDisposition.split(";")[1];
        print(filename);
        filename = filename.substring(18);
        filename.replaceAll('"', '');
        filename = utf8.decode(latin1.encode(filename));
        print("Filename is ${filename}");
        File downloadedFile = File("$BASEDIR${savePath}/${filename}");
        downloadedFile.createSync(recursive: true);
        await downloadedFile.writeAsBytes(dlResponse.bodyBytes);
        print("File downloaded and saved on disk");
        return filename;
      }
      else{
        return "";
      }
    }
    return "";
  }

  /// Télécharge un lien disponible sur celene (ouvre ce lien dans le navigateur)
  Future<String> _downloadLink(String link,String savePath) async {
    await FileEntry.openLink(link);
    return "downloading";
  }
  /// Fonction faisant appel aux fonctions de téléchargement en fonction du type de fichier passé en paramètre
  Future<String> downloadElement(link, eltType, savePath) async{
    Map<String,Function(String,String)> functionMap = _bindParser(this);
    return await functionMap[eltType]!.call(link,savePath);
  }

  /// Fonction associant un type de fichier disponible sur celene (String) à une fonction de téléchargement
  Map<String, Function(String,String)> _bindParser(CeleneParser parser) {
    return {
      "Fichier": parser._downloadFile,
      "Dossier": parser._downloadFolder,
      "URL": parser._downloadLink,
    };
  }
}


/// Classe représentant un cours disponible sur celene
class Classes{
  String name;
  String courseID = "";
  String celeneID;
  String savePath = "";

  Classes(this.name, this.celeneID){
    this.courseID = Uuid().v1().substring(0,5);
    this.savePath = courseID;
  }
  /// mettre à jour le chemin de sauvgarde si non initialisé
  void updateSavePath(){
    savePath = courseID;
  }
  void setSavePath(String savePath){
    this.savePath = savePath;
  }


}

/// Classe représentant une ressource disponible sur une page d'un cours sur celene
class Course{
  String name;
  String link;
  String type;
  bool downloaded = false;
  bool fromFolder = false;
  FileEntry? associatedFile = null;

  Course(this.name,this.link,this.type);

  /// Transforme un élément html depuis la page celene vers une cours
  static Course? constructFromCeleneInfo(Bs4Element data){
    Bs4Element? courseAtag = data.find("a",class_: "aalink stretched-link");
    if (courseAtag != null){
      String? courseLink = courseAtag.getAttrValue("href");
      Bs4Element? span = courseAtag.find("span", class_: "instancename");
      if (span != null){
        Bs4Element? accessHide = span.find("span", class_: "accesshide");
        if (accessHide != null && courseLink != null){
          String courseType = accessHide.getText(strip: true);
          accessHide.decompose();
          String courseName = span.getText(strip: true);
          return Course(courseName,courseLink, courseType);
        }
      }
    }
    return null;
  }

  /// Transforme un objet File en un objet Course, utile notamment pour les fichiers d'un dossier sur celene
  static constructFromFileInfo(FileEntry courseFile){
    Course subCourse = Course(courseFile.name, "https://celene.insa-cvl.fr", courseFile.type);
    subCourse.updateDownloadStatus();
    subCourse.fromFolder = true;
    return subCourse;
  }
  /// Met à jour le statut de téléchargement d'une ressource
  void updateDownloadStatus(){
    downloaded = true;
  }
  /// Attribue un fichier associé pour pouvoir ensuite ouvrir ce dit fichier
  void setFile(FileEntry file){
    associatedFile = file;
  }
  /// Fonctions d'affichage
  @override
  String toString() {
    // TODO: implement toString
    return "Nom : ${name}    Type : ${type}";
  }
}
