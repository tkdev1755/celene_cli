

import 'dart:io';

import 'package:celene_cli/view/view.dart';

import '../model/celeneObject.dart';
import 'package:dart_console/dart_console.dart';

class ShowClassContentView extends View {




  List<Course> options = [];
  int selectedIndex = 0;
  bool loadingMessageDrawn = false;

  ShowClassContentView(super.controller,{super.parent});

  @override
  void draw() {
    if (controller.getFlag("downloadCourse")){

      return;
    }
    console.clearScreen();
    console.setForegroundColor(ConsoleColor.cyan);
    console.writeLine('=== Selectionne le fichier à télécharger/ouvrir ===');
    console.resetColorAttributes();
    for (int i = 0; i < options.length; i++) {
      String textToWrite = options[i].downloaded ? '${options[i]} (Téléchargé)' : '${options[i]}';
      if (i == selectedIndex) {
        ConsoleColor dLSelectedColor = options[i].downloaded ? ConsoleColor.green : ConsoleColor.yellow;
        console.setForegroundColor(ConsoleColor.black);
        console.setBackgroundColor(dLSelectedColor);
        console.writeLine('> $textToWrite');
        console.resetColorAttributes();
      } else {
        console.writeLine('  $textToWrite');
      }
    }
  }
  void drawLoadingScreen(){
    console.clearScreen();
    console.writeLine("----- Chargement du Cours -----");
    console.resetColorAttributes();
  }
  @override
  Future<void> handleInput() async {
    var key = await console.readKey();
    if (key.isControl) {
      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          selectedIndex = (selectedIndex - 1) % options.length;
          break;
        case ControlCharacter.arrowDown:
          selectedIndex = (selectedIndex + 1) % options.length;
          break;
        case ControlCharacter.ctrlC:
          controller.handleInput("exit", null);
          break;
        case ControlCharacter.enter:
          print("This operation can take some time");
          await controller.handleInput("openCourse",selectedIndex,parent: this);
          break;
        case ControlCharacter.escape:
          controller.handleInput("exit", null);
          break;
        case ControlCharacter.backspace:
          controller.handleInput("return", null);
        default:
        // Ignorer les autres touches
          break;
      }
    }

  }

  @override
  Future<void> run() async{
    if (!initializedState && !initializingState){
      if (!loadingMessageDrawn){
        drawLoadingScreen();
        loadingMessageDrawn = true;
      }
      await initState();
    }
    else if (initializedState){
      draw();
      await handleInput();
    }

    // TODO: implement run
  }

  @override
  Future<void> initState() async{
    initializingState = true;
    options = await super.controller.getData() as List<Course>;
    print("Finished getting options");
    initializingState = false;
    initializedState = true;
    // TODO: implement initState
  }

}