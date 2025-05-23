

import 'package:celene_cli/celeneCLI.dart';
import 'package:celene_cli/controller/addCourseController.dart';
import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/controller/importClassesController.dart';
import 'package:celene_cli/controller/navigator.dart';
import 'package:celene_cli/controller/optionsController.dart';
import 'package:celene_cli/controller/showClassContentController.dart';
import 'package:celene_cli/model/DBManager.dart';
import 'package:celene_cli/model/celeneObject.dart';
import 'package:celene_cli/view/addCourseView.dart';
import 'package:celene_cli/view/importClassesView.dart';
import 'package:celene_cli/view/optionsView.dart';
import 'package:celene_cli/view/showClassContentView.dart';

import '../view/view.dart';

/*class ChooseCourseController{

  List<Classes> classes;


  ChooseCourseController(this.classes);

  List<String> getData(){
    return classes.map((e)=>e.name).toList();
  }
  Classes sendGetClassesData(int index){
    if (index > classes.length){
      throw Exception();
    }
    return classes[index];
  }

  switchView(){

  }
}*/


class ChooseCourseController extends Controller{

  CeleneParser celene;
  DBManager db;
  @override
  // TODO: implement flags
  ChooseCourseController(this.celene,this.db,){
    super.flags = {
    };
  }

  @override
  getData() {
    return celene.courses.map((e)=>e.name).toList();
  }

  @override
  handleInput(String type, data, {View? parent}) {
    // TODO: implement handleInput
    switch(type){
      case "openCourse":
        openCourseView(data,parent: parent);
        break;
      case "addCourse":
        openAddCourseView(parent: parent);
        break;
      case "importClasses":
        openImportCourseView(parent: parent);
        break;
      case "openOptions":
        openOptionsView(parent: parent);
        break;
      case "exit":
        quitApp();
        break;

    }
  }

  openCourseView(data, {View? parent}){
    if (data.runtimeType != int){
      throw ArgumentError.value(data);
    }
    if (!celene.loggedIn){

    }
    Classes selectedClass = celene.courses[data];
    navigator.push(ShowClassContentView(ShowClassContentController(celene,db,selectedClass),parent: parent));

  }

  openAddCourseView({View? parent}){
    navigator.push(AddCourseView(AddCourseController(celene,db),parent: parent));
  }

  openImportCourseView({View? parent}){
    navigator.push(ImportClassesView(ImportClassesController(celene,db),parent : parent));
  }

  openOptionsView({View? parent}){
    navigator.push(OptionsView(OptionsController(celene,db), parent: parent));
  }

  @override
  quitApp(){
    db.dumpChanges();
    Navigator.exitProgram();
  }

  @override
  bool getFlag(String flag) {
    // TODO: implement getFlag
    throw UnimplementedError();
  }

  @override
  setFlag(String flag) {
    // TODO: implement setFlag
    throw UnimplementedError();
  }

  @override
  setData(dynamic data) {
    // TODO: implement setData
    throw UnimplementedError();
  }
  
}