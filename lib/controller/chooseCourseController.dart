

import 'package:celene_cli/celeneCLI.dart';
import 'package:celene_cli/controller/addCourseController.dart';
import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/controller/navigator.dart';
import 'package:celene_cli/controller/showClassContentController.dart';
import 'package:celene_cli/model/DBManager.dart';
import 'package:celene_cli/model/celeneObject.dart';
import 'package:celene_cli/view/addCourseView.dart';
import 'package:celene_cli/view/chooseCourseView.dart';
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
      print("Before adding sending to the new page, logging in is necessary");

    }
    Classes selectedClass = celene.courses[data];
    navigator.push(ShowClassContentView(ShowClassContentController(celene,db,selectedClass),parent: parent));


  }

  openAddCourseView({View? parent}){
    navigator.push(AddCourseView(AddCourseController(celene,db),parent: parent));
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