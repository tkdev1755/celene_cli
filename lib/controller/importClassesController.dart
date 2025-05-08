

import 'package:celene_cli/celeneCLI.dart';
import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/controller/navigator.dart';
import 'package:celene_cli/model/fileManager.dart';
import 'package:celene_cli/view/view.dart';
import '../model/DBManager.dart';
import '../model/celeneObject.dart';

class ImportClassesController extends Controller{
  CeleneParser celene;
  DBManager db;
  List<Classes> joinedClasses = [];
  ImportClassesController(this.celene,this.db){
   super.flags = {
     "fetchedData" : false
   };
  }

  @override
  getData() async {
    if (!getFlag("fetchedData")){
      joinedClasses = await celene.getUserJoinedClasses();
      setFlag("fetchedData");

    }
    return joinedClasses;
  }


  @override
  handleInput(String type, data, {View? parent}) async{
    switch(type){
      case "renameCourse":
        return renameCourse(data.$1, data.$2);
      case "removeCourse":
        return removeCourse(data);
      case "saveChanges":
        return saveCourses();
      case "return":
        getToPreviousPage();
        break;
      case "exit":
        quitApp();
        break;
      case "openCourse":
        await openCourseOnCelene(data);
        break;
    }
  }

  renameCourse(String newName,int index){
    if (index > joinedClasses.length-1 || newName.isEmpty){
      return -1;
    }
    joinedClasses[index].name = newName;
    return 0;
  }

  removeCourse(int index){
    if (index > joinedClasses.length-1){
      return -1;
    }
    joinedClasses.removeAt(index);
    return 0;
  }
  saveCourses(){
    for (Classes i in joinedClasses){
      db.addCourse(i);
    }
  }
  openCourseOnCelene(int index) async{
    if (index > joinedClasses.length-1){
      return -1;
    }
    String classLink  = celene.getClassUrl(joinedClasses[index].celeneID).toString();
    await FileEntry.openLink(classLink);
    return 0;
  }
  getToPreviousPage(){
    navigator.pop();
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
  bool getFlag(String flag) {
    if (flags.containsKey(flag)){
      return flags[flag]!;
    }
    else{
      throw Exception("Flag doesn't exists");

    }
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

}