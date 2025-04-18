
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:celene_cli/model/celeneObject.dart';
import 'package:celene_cli/model/fileManager.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'extensions.dart';
class DBManager{
  String DB_PATH = "db.json";
  Map<String,dynamic> _data  = {};

  DBManager(){
    File storageFile = File(DB_PATH);
    if (!storageFile.existsSync()){
      print("dbFile does not exist, creating it");
      storageFile.createSync();
      _data = {};
    }
    else{
      storageFile.openRead();
      Map<String,dynamic> res = jsonDecode(storageFile.readAsStringSync());
      _data = res;
    }
  }

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

  List<Classes> reconstructCourses(){
    List<Classes> classes = [];
    if (_data.isNotEmpty){
      if (_data.containsKey("courses")){
        for (Map<String,dynamic> i in _data["courses"]){
          Classes newClass = Classes(i["name"], i["cID"]);
          newClass.courseID = i["id"];
          newClass.updateSavePath();
          classes.add(newClass);

        }
        return classes;
      }
    }
    return classes;
  }

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
            print(i);
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

  addData(String key, dynamic value){
    if (!_data.containsKey(key)){
      _data[key] = value;
    }
    else{
      throw Exception("Value already exists in \"database\"");
    }
  }

  saveUserCredentialPreferences((bool,String) preferences){
    _data["credentialSaved"]= preferences[0];
    if (preferences[0]){
      _data["username"] = preferences[1];
    }
  }

  saveUserSecureStoragePreferences(bool preferences){
    _data["secureStorageStatus"] = preferences;
  }

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
      print("The following file is a folder, so we are obligated to unzip it");
      String folderPath = "$courseID/${filename.substring(0, (filename.length-4))}";
      final bytes = File(("$courseID/$filename")).readAsBytesSync();
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
  void addCourse(Classes classes){
    if (!_data.containsKey("courses")){
        _data["courses"] = [];
    }
    Map<String,dynamic> serializedClass = {
      "name" : classes.name,
      "cID" : classes.celeneID,
      "id" : classes.courseID
    };
    _data["courses"].add(serializedClass);
  }

  Future<void> dumpChanges() async{
    print("Dumping changes to file");
    File dbFile = File(DB_PATH);
    if (dbFile.existsSync()){
      dbFile.writeAsStringSync(jsonEncode(_data));
      print("Dumped changes to file");
    }
  }
}