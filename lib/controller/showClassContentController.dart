

import 'dart:io';
import 'dart:math';

import 'package:celene_cli/celeneManager.dart';
import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/model/fileManager.dart';

import '../model/DBManager.dart';
import '../model/celeneObject.dart';
import '../view/view.dart';
import 'navigator.dart';

class ShowClassContentController extends Controller{

  CeleneParser celene;
  DBManager db;
  Classes selectedClass;
  List<Course> courses = [];
  bool downloadFlag = false;

  ShowClassContentController(this.celene, this.db, this.selectedClass){
    super.flags = {
      "downloadCourse" : false,
    };
  }


  @override
  getData() async {
    print("COURSE ID is ${selectedClass.courseID}");
    courses = await celene.getClassData(selectedClass.celeneID, selectedClass.courseID);
    return courses;
  }

  @override
  handleInput(String type, data,{View? parent}) async {
    // Received a course and now trying to download it, or open it
    switch(type){
      case "openCourse":
        await handleCourse(courses[data]);
        break;
      case "return":
        getToPreviousPage();
        break;
      case "exit":
        quitApp();
    }
    // Expects a
  }


  handleCourse(data) async{
    Course selectedCourse = data as Course;
    if (selectedCourse.downloaded){
      print("OpeningFile !");
      await FileEntry.openFile(selectedCourse.associatedFile!, folder: selectedCourse.fromFolder);
    }
    else{
      setFlag("downloadCourse");
      String filename = await celene.downloadElement(selectedCourse.link, selectedCourse.type, selectedClass.savePath);
      if (selectedCourse.type != 'URL'){
        selectedCourse.associatedFile = FileEntry(filename, selectedCourse.name, selectedCourse.type, selectedClass.courseID, true);
        selectedCourse.updateDownloadStatus();
      }
      db.addFile(data, filename, selectedClass.courseID);
      print("Finished downloading");
      setFlag("downloadCourse");
    }
  }

  getToPreviousPage(){
    navigator.pop();
  }
  @override
  quitApp(){
    db.dumpChanges();
    Navigator.exitProgram();
  }

  @override
  bool getFlag(String flag) {
    // TODO: implement getFlag
    if (flags.containsKey(flag)){
      return flags[flag]!;
    }
    else{
      throw Exception("Flag doesn't exists");

    }
  }

  @override
  setFlag(String flag) {
    // TODO: implement setFlag
    if (flags.containsKey(flag)){
      flags[flag] = !flags[flag]!;
    }
    else{
      throw Exception("Trying to set a non existant flag");
    }
  }

  @override
  setData(dynamic data) {
    // TODO: implement setData
    throw UnimplementedError();
  }

}