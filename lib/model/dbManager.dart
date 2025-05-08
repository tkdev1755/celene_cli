
import 'dart:convert';
import 'dart:io';

import 'package:celene_cli/model/celeneObject.dart';
import 'package:celene_cli/model/fileManager.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'extensions.dart';

/// {@category USER-DATA}
/// Classe gérant les préférences utilisateurs
class DBManager{

  /// Chemin du fichier contenant les préférences utilisateurs
  String DB_PATH = "${BASEDIR}db.json";

  /// Objet contenant les informations utilistaeur
  Map<String,dynamic> _data  = {};

  DBManager(){
    File storageFile = File(DB_PATH);
    if (!storageFile.existsSync()){
      logger("dbFile does not exist, creating it");
      storageFile.createSync();
      _data = {};
    }
    else{
      Stream<List<int>> file = storageFile.openRead();
      if (storageFile.lengthSync() == 0){
        _data = {};
      }
      else{
        Map<String,dynamic> res = jsonDecode(storageFile.readAsStringSync());
        _data = res;
      }
    }
  }
  /// Fonction reconstruisant les listes d'objets nécessaire au bon fonctionnement de l'application
  Map<String,dynamic> reconstruct(){
    List<Classes> courses = reconstructCourses();
    Map<String, List<FileEntry>> files = reconstructFileIndex();
    String? username = _data["username"];
    bool credentialSaved = _data["credentialSaved"] ?? false;
    bool secureStorageStatus = _data["secureStorageStatus"] ?? false;
    return {
      "courses" : courses,
      "files" : files,
      "credentialSaved" : credentialSaved,
      "secureStorageStatus" :secureStorageStatus,
      "username" : username,

    };

  }

  /// Fonction reconstruisant les cours celene enregistrés par l'utilisateur
  List<Classes> reconstructCourses(){
    List<Classes> classes = [];
    if (_data.isNotEmpty){
      if (_data.containsKey("courses")){
        for (Map<String,dynamic> i in _data["courses"]){
          Classes newClass = Classes(i["name"], i["cID"]);
          newClass.updateSavePath();
          classes.add(newClass);
        }
        return classes;
      }
    }
    return classes;
  }
  /// Fonction reconstruisant les fichiers téléchargés par l'utilisateur
  Map<String, List<FileEntry>> reconstructFileIndex(){
    Map<String,List<FileEntry>> fileIndex = {};
    if (_data.isNotEmpty){
      if (_data.containsKey("files")){
        Map<String, dynamic> test = _data["files"];
        test.forEach((k,v){
          if (!fileIndex.containsKey(k)){
            fileIndex[k] = [];
          }
          for (dynamic i in v){
            String? parent = i.containsKey("parent") ? i["parent"] : null;
            FileEntry newFile = FileEntry(i["name"], i["entryName"], i["type"], k, i["latest"],parent: parent);
            fileIndex[k]!.add(newFile);
            if (i["type"] == "Dossier"){
              int index = fileIndex[k]!.indexOf(newFile);
              fileIndex[k]![index].children = [];
              for (Map<String,dynamic> j in i["children"]){
                fileIndex[k]![index].children!.add(FileEntry(j["name"], j["entryName"], j["type"], k, j["latest"],parent: j["parent"]));
              }
            }
          }
        });

      }
    }
    return fileIndex;
  }

  // Permet d'ajouter une clé à Data
  addData(String key, dynamic value){
    if (!_data.containsKey(key)){
      _data[key] = value;
    }
    else{
      throw Exception("Value already exists in \"database\"");
    }
  }

  /// Fonction sauvegardant les préférences de l'utilisataur vis à vis de la connexion automatique
  saveUserCredentialPreferences((bool,String) preferences){
    _data["credentialSaved"]= preferences[0];
    if (preferences[0]){
      _data["username"] = preferences[1];
    }
  }
  bool getUserCredentialPreferences(){
    return _data.containsKey("credentialSaved") ? _data["credentialSaved"] : false;
  }
  /// Fonction sauvegardant les préférences de l'utilisateur vis à vis de la persistance de session
  saveUserSecureStoragePreferences(bool preferences){
    _data["secureStorageStatus"] = preferences;
  }

  bool getSecureStorageStatus(){
    return _data.containsKey("secureStorageStatus") ? _data["secureStorageStatus"] : false;
  }
  String? getUsername(){
    return _data["username"];
  }

  int clearDB(){
    _data.clear();
    return 0;
  }
  // For debugging purposes
  int getDataLength(String key){
    return _data[key].length;
  }
  /// Fonction ajoutant un fichier téléchargé à l'index des fichiers téléchargé
  void addFile(Course file,String filename, String courseID){
    if (!_data.containsKey("files")){
      _data["files"] = {};
    }
    if (!_data["files"]!.containsKey(courseID)){
      _data["files"][courseID] = [];
    }
    Map<String,dynamic> serializedFile = {
      "name" : filename,
      "entryName" : file.name,
      "type" : file.type,
      "parent" : null,
      "latest" : true
    };
    int latestCourse = _data["files"][courseID].indexWhere((e) => e["latest"] == true);
    if (latestCourse > 0){
      _data["files"]["coursesID"][latestCourse]["latest"] = false;
    }
    _data["files"][courseID].add(serializedFile);
    int lastcourse = _data["files"][courseID].length;
    if (file.type == "Dossier"){
      logger("The following file is a folder, so we are obligated to unzip it");
      String folderPath = "$BASEDIR$courseID/${filename.substring(0, (filename.length-4))}";
      final bytes = File(("$BASEDIR$courseID/$filename")).readAsBytesSync();
      Archive archive = ZipDecoder().decodeBytes(bytes);
      _data["files"][courseID][lastcourse-1]["children"] = [];
      for (final uFile in archive){
        final subFilename = uFile.name;
        final filePath = "$folderPath/$subFilename";
        Map<String,dynamic> serializedFile = {
          "name" : subFilename,
          "entryName" : subFilename,
          "type" : "Fichier",
          "courseID" : courseID,
          "parent" : filename.substring(0, filename.length-4),
          "latest" : false
        };
        _data["files"][courseID][lastcourse-1]["children"].add(serializedFile);
        if (uFile.isFile){
          File outFile = File(filePath)..createSync(recursive:  true);
          outFile.writeAsBytesSync(uFile.content as List<int>);
        }
        else{
          Directory(filePath).createSync(recursive: true);
        }
      }
    }
  }
  /// Fonction ajoutant un cours à l'index de cours existant
  void addCourse(Classes classes){
    if (!_data.containsKey("courses")){
        _data["courses"] = [];
    }
    Map<String,dynamic> serializedClass = {
      "name" : classes.name,
      "cID" : classes.celeneID,
      "id" : classes.celeneID
    };
    _data["courses"].add(serializedClass);
  }

  /// Fonction écrivant les changements effectués sur la "base de donnée" sur le disque
  Future<void> dumpChanges() async{
    logger("Dumping changes to file");
    File dbFile = File(DB_PATH);
    if (dbFile.existsSync()){
      dbFile.writeAsStringSync(jsonEncode(_data));
      logger("Dumped changes to file");
    }
  }
}