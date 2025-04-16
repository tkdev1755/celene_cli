

import 'package:celene_cli/celeneManager.dart';
import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/view/view.dart';

import '../model/DBManager.dart';
import '../model/celeneObject.dart';

class AddCourseController extends Controller{
  CeleneParser celene;
  DBManager db;
  Map<String,String> data = {
    "name" :"",
    "url" : "",
  };
  AddCourseController(this.celene,this.db,){
    super.flags = {
      "firstField" : true,
      "secondField" : false,
    };
  }

  @override
  getData() {
    return data;
  }

  @override
  bool getFlag(String flag) {
    if (flags.containsKey(flag)){
      return flags[flag]!;
    }
    else{
      throw Exception("Flag doesn't exists");

    }
    // TODO: implement getFlag
  }

  @override
  handleInput(String type, recievedData, {View? parent}) {
    // TODO: implement handleInput
    switch (type){
      case "addCourse":
        if (!getFlag("firstField") && !getFlag("secondField")){
          int celeneID = CeleneParser.getIDFromUrl(data["url"]!);
          Classes newClass = Classes(data["name"]!, "$celeneID");
          db.addCourse(newClass);
          celene.courses.add(newClass);
          navigator.pop();

        }
    }

  }

  @override
  quitApp() {
    db.dumpChanges();
    throw UnimplementedError();
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

  @override
  setData(dynamic recievedData) {
    // Expect a string in Data, determines which form to use with the flags, and change the data accordingly
    if (flags["firstField"] ?? true){
      data["name"] = recievedData;
      setFlag("firstField");
      setFlag("secondField");
    }
    else if (flags["secondField"] ?? false){
      data["url"] = recievedData;
      setFlag("secondField");
    }
    // TODO: implement setData
  }

}