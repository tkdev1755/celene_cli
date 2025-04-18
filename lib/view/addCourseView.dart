


import 'dart:io';

import 'package:celene_cli/celeneCLI.dart';
import 'package:celene_cli/view/view.dart';

class AddCourseView extends View{


  List<String> options = [];
  int selectedIndex = 0;

  AddCourseView(super.controller,{super.parent});

  @override
  void draw() {
    console.clearScreen();

    console.writeLine('=== Ajouter un élément ===\n');
    console.resetColorAttributes();

    console.write('Nom : ');
    console.write('${controller.getData()["name"]}');
    console.write('\n');
    console.write('URL : ');
    console.write('${controller.getData()["url"]}');
    console.write('\n');

  }

  @override
  Future<void> handleInput() async {
    String data = stdin.readLineSync() ?? "";
    controller.setData(data);
    if (!controller.getFlag("firstField") && !controller.getFlag("secondField")){
      controller.handleInput("addCourse", null);
    }
  }

  @override
  Future<void> initState() {
    // TODO: implement initState
    throw UnimplementedError();
  }

  @override
  Future<void> run() async {
    draw();
    await handleInput();
    // TODO: implement run
  }



}