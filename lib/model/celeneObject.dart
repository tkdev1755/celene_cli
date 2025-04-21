
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
  
  static int getIDFromProfileUrl(String url){
    Map<String,String> params  = Uri.parse(url).queryParameters;
    if (!params.containsKey("course")){
      return -1;
    }
    return int.parse(params["course"]!);
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
      logger("CREDENTIAL NULL SO DOING NOTHING");
      throw Exception("Credentials didn't exist at the time of creation");
    }
    logger("creds are $_credentials");
    _casAuth ??= CASAuth();

    try{

    }
    on Exception{
      logger("Exception while connecting to CAS");
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
      logger("Saving session NOW !");
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
      logger(casAuth!.secureStorage.get("casCookies")?.value);
    }*/
    return saveResult;
  }

  /// Charge la session celene si la persistance de session à été activée
  ///
  /// Retourne vrai si la session a été chargée correctement, faux autrement
  bool loadCeleneSession(){
    _casAuth ??= CASAuth();

    // The tuple represents $1-> name of the value stored in secure storage ; $2 -> name of the cookie in the cookiejar ; $3 -> url of the cookie
    bool result = _casAuth!.loadCASSession([("moodleID","MOODLEID1_","https://celene.insa-cvl.fr/"), ("moodleSession","MoodleSession","https://celene.insa-cvl.fr")]);
    loggedIn = result;
    /*if (sessionValue == null){
      logger("Nothing to load h ere");
      return false;
    }
    logger("We do have a value");
    Map<String,dynamic> cookies = sessionValue.value;
    logger("Here is the value -> $cookies");
    DateTime sessionDate = DateFormat("dd-MM-yyyy/HH:mm:ss").parse(cookies["sessionDate"]);
    logger("Sessions delta is ${DateTime.now().difference(sessionDate).inMinutes}");
    if (DateTime.now().difference(sessionDate).inMinutes > 30){
      logger("Session too old, creating a new session");
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
    logger("Added successfully ${cookies.length}");*/
    return result;
  }
  /// Récupère et lit la page d'un cours sur celene, retourne la liste des ressources disponibles sur cette page
  Future<List<Course>> getClassData(cID,classID) async{
    List<FileEntry> downloadedCourse = files.containsKey(classID) ? files[classID]! : [];
    logger(files);
    logger("Loaded downloaded courses");
    List<Course> courses = [];
    if (!loggedIn){
      logger("Not logged in, need to log in to Celene");
      bool result = await loginToCelene();
      if (!result){
        throw Exception("ERROR WHILE CONNECTING TO CELENE");
      }

      logger("Successfully logged in to Celene");
    }
    logger(_casAuth?.session.cookieStore.cookies);
    if (_casAuth != null){
      Uri classUrl = getClassUrl(cID);
      logger("Now retrieving class data : class url is ${classUrl}");
      //casAuth!.prepareRequest();
      logger("CAS AUTH HEADERS");
      Response classData;
      try{
        classData = await _casAuth!.session.get(classUrl, headers: _casAuth!.headers);
      }
      on ClientException{
        classData = await _casAuth!.session.get(classUrl, headers: _casAuth!.headers);
      }
      logger("Get response finished");
      if (classData.statusCode == 200){
        logger("GET RESPONSE 200 -> Now parsing the page");
        //casAuth!.session.updateCookies(classData);
        //casAuth!.prepareRequest();
        BeautifulSoup soup = BeautifulSoup(classData.body);
        //logger(soup.prettify());
        Bs4Element? topic = soup.find('ul', class_: 'topics');
        List<Bs4Element> sections = soup.findAll("li", class_: "section course-section main");
        for (Bs4Element i in sections){
          logger("SectionName");
          String? topic = i.find("h3", class_: "sectionname")?.text.trim();
          List<Bs4Element> li_elements = i.findAll("li", class_:"activity activity-wrapper");
          logger("Found ${li_elements.length} li_elements");
          for (Bs4Element i in li_elements){
            Course? newCourse = Course.constructFromCeleneInfo(i,parent: topic);
            if (newCourse != null){
              FileEntry? associatedFile = downloadedCourse.where((e) => e.entryName == newCourse.name).toList().firstOrNull;
              newCourse.downloaded = associatedFile != null;
              newCourse.associatedFile = associatedFile;
              if (newCourse.type == "Dossier" && newCourse.downloaded){
                logger("The folder is downloaded so we have to add all files in this folder");
                for (FileEntry j in (newCourse.associatedFile!.children)!){
                  logger("Adding subCourse");
                  Course subCourse = Course.constructFromFileInfo(j,parent: topic);
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
      }
      return courses;
    }
    return courses;
  }
  /// Fonction récupérant les cours rejoint par l'utilisateur sur Celene
  Future<List<Classes>> getUserJoinedClasses() async{
    List<Classes> joinedClasses = [];
    // Need to go to this weird endpoint to see the courses of the user
    Uri joinedClassesURI = Uri.parse("https://celene.insa-cvl.fr/user/profile.php?showallcourses=1");
    if (!loggedIn){
      logger("Not logged in, need to log in to Celene");
      bool result = await loginToCelene();
      if (!result){
        throw Exception("ERROR WHILE CONNECTING TO CELENE");
      }
      logger("Successfully logged in to Celene");
    }
    if (_casAuth != null) {
      //casAuth!.prepareRequest();
      logger("CAS AUTH HEADERS");
      Response classData;
      try {
        classData =
        await _casAuth!.session.get(joinedClassesURI, headers: _casAuth!.headers);
      }
      on ClientException {
        classData =
        await _casAuth!.session.get(joinedClassesURI, headers: _casAuth!.headers);
      }
      if (classData.statusCode == 200){
        logger("Got all data from class !");
        BeautifulSoup soup = BeautifulSoup(classData.body);
        List<Bs4Element> classesDiv = soup.findAll("li",class_: "contentnode");
        Bs4Element? coursesDL = classesDiv.where((e) => e.find("dt", string: r"Profils de cours") != null).firstOrNull;
        if (coursesDL == null){
          logger("Found no div and no UL ");
          return [];
        }
        List<Bs4Element> li_elements = coursesDL.findAll("li");
        logger("Found ${li_elements.length} li_elements");
        for (Bs4Element i in li_elements){
          Classes? newClass = Classes.constructFromCeleneInfo(i);
          if (newClass != null){
            joinedClasses.add(newClass);
          }
        }
        return joinedClasses;
      }
    }
    return joinedClasses;
  }

  /// Téléchage un fichier disponible sur celene
  Future<String> _downloadFile(String link,savePath) async {
    if (!loggedIn){
      loginToCelene();
    }
    logger("Now Downloading file");
    Uri uri = Uri.parse(link);
    logger("Sending GET to ${uri}");
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
      logger("Successfully downloaded the file");
      String filename = "unknownFile";
      logger(downloadResponse.headers);
      String? contentDisposition = downloadResponse.headers["content-disposition"];
      if (contentDisposition !=  null){
        logger("Content disposition is not null so we may have a filename");
        String filename = contentDisposition.split(";")[1];
        logger("filename length ${filename.length}");
        filename = filename.substring(11, filename.length-1);
        filename = utf8.decode(latin1.encode(filename));
        logger("Filename is $filename");
        File downloadedFile = File("$BASEDIR$savePath/$filename");
        downloadedFile.createSync(recursive: true);
        await downloadedFile.writeAsBytes(downloadResponse.bodyBytes);
        logger("File downloaded and saved on disk");
        return filename;
      }
      else{
        return "";

      }

    }
    else{
      logger("Error while trying to download the file, ${downloadResponse.statusCode} |${downloadResponse.reasonPhrase}");
      logger("${downloadResponse.body} \n ${downloadResponse.headers}");
      return "";
    }
  }

  /// Télécharge un dossier disponible sur celene
  Future<String> _downloadFolder(String link,String savePath) async {
    logger("Downloading folder");
    int objID = getIDFromUrl(link);
    Uri dlLink = getFolderDownloadLink(objID);
    if (!loggedIn){
      loginToCelene();
    }
    logger("Now sending data");
    Response dlResponse;
    try {
      dlResponse = await _casAuth!.session.get(dlLink, headers: _casAuth!.headers);
    }
    on ClientException{
      dlResponse = await _casAuth!.session.get(dlLink, headers: _casAuth!.headers);
    }
    logger("Recieved data");
    if (dlResponse.statusCode == 200){
      logger("File Download successful");
      String filename = "UnknownFile";
      String? contentDisposition = dlResponse.headers["content-disposition"];
      if (contentDisposition !=  null){
        String filename = contentDisposition.split(";")[1];
        logger(filename);
        filename = filename.substring(18);
        filename.replaceAll('"', '');
        filename = utf8.decode(latin1.encode(filename));
        logger("Filename is ${filename}");
        File downloadedFile = File("$BASEDIR${savePath}/${filename}");
        downloadedFile.createSync(recursive: true);
        await downloadedFile.writeAsBytes(dlResponse.bodyBytes);
        logger("File downloaded and saved on disk");
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
  static Classes? constructFromCeleneInfo(Bs4Element data){
    Bs4Element? classURL = data.find("a");
    if (classURL == null){
      logger("No a containing info Found");
      return null;
    }
    String? courseURL = classURL.getAttrValue("href");
    String? courseName = classURL.text.trim();
    if (courseURL == null){
      logger("No courseURL");
      return null;
    }
    if (courseName == ""){
      logger("CourseName not found");
      return null;
    }
    int celeneID = CeleneParser.getIDFromProfileUrl(courseURL);
    return Classes(courseName, "$celeneID");
  }

  @override
  String toString() {
    return name;
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
  String? topic;
  Course(this.name,this.link,this.type, {this.topic});

  /// Transforme un élément html depuis la page celene vers une cours
  static Course? constructFromCeleneInfo(Bs4Element data,{String? parent}){
    Bs4Element? courseAtag = data.find("a",class_: "aalink stretched-link");
    logger("Course topic ! ${parent}");
    if (courseAtag != null){
      String? courseLink = courseAtag.getAttrValue("href");
      Bs4Element? span = courseAtag.find("span", class_: "instancename");
      if (span != null){
        Bs4Element? accessHide = span.find("span", class_: "accesshide");
        if (accessHide != null && courseLink != null){
          String courseType = accessHide.getText(strip: true);
          accessHide.decompose();
          String courseName = span.getText(strip: true);

          return Course(courseName,courseLink, courseType,topic: parent);
        }
      }
    }
    return null;
  }

  /// Transforme un objet File en un objet Course, utile notamment pour les fichiers d'un dossier sur celene
  static constructFromFileInfo(FileEntry courseFile, {String? parent}){
    Course subCourse = Course(courseFile.name, "https://celene.insa-cvl.fr", courseFile.type, topic: parent);
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
    return "Nom : ${name} ${topic != null ? "($topic)" : ""}    Type : ${type}";
  }
}
