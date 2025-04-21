

import 'dart:io';

import 'package:celene_cli/view/view.dart';

import '../model/celeneObject.dart';
import 'package:dart_console/dart_console.dart';

class ShowClassContentView extends View {
  List<Course> options = [];
  int selectedIndex = 0;
  bool loadingMessageDrawn = false;
  int displayedSubList = 0;
  int maxSublists = 0;
  int optionLength = 0;
  static int MAX_DISPLAY_LINES = 5;
  ShowClassContentView(super.controller,{super.parent});

  @override
  void draw() {
    if (controller.getFlag("downloadCourse")){
      return;
    }
    MAX_DISPLAY_LINES = ((console.windowHeight/2).floor())-5 > 5 ? ((console.windowHeight/2).floor())-5 : 5 ;
    maxSublists = (optionLength / MAX_DISPLAY_LINES).ceil();
    int startIndex = (displayedSubList)*MAX_DISPLAY_LINES;
    int endIndex = (displayedSubList+1)*(MAX_DISPLAY_LINES);
    int displayEndIndex = endIndex < options.length ? endIndex : options.length;
    console.clearScreen();
    console.setForegroundColor(ConsoleColor.cyan);
    console.writeLine('=== Selectionne le fichier à télécharger/ouvrir ===');
    console.resetColorAttributes();
    for (int i = startIndex; i < displayEndIndex; i++) {
      String textToWrite = options[i].downloaded ? '${options[i]} (Téléchargé)' : '${options[i]}';
      if (i == selectedIndex) {
        ConsoleColor dLSelectedColor = options[i].downloaded ? ConsoleColor.green : ConsoleColor.yellow;
        console.setForegroundColor(ConsoleColor.black);
        console.setBackgroundColor(dLSelectedColor);
        console.writeLine('> $textToWrite');
        console.resetColorAttributes();
        console.write("\n");
      } else {
        console.writeLine('  $textToWrite');
        console.write("\n");
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
    int startIndex = (displayedSubList)*MAX_DISPLAY_LINES;
    int endIndex = (displayedSubList+1)*(MAX_DISPLAY_LINES);
    int displayEndIndex = endIndex < options.length ? endIndex : options.length;
    var key = await console.readKey();
    if (key.isControl) {
      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          if (selectedIndex == startIndex){
            displayedSubList = (displayedSubList -1) % maxSublists;
          }
          selectedIndex = (selectedIndex - 1) % options.length;
          break;
        case ControlCharacter.arrowDown:
          if (selectedIndex+1 == displayEndIndex){
            displayedSubList = (displayedSubList +1) % maxSublists;
          }
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
    optionLength = options.length;
    MAX_DISPLAY_LINES = ((console.windowHeight/2).floor())-5 > 5 ? ((console.windowHeight/2).floor())-5 : 5 ;
    maxSublists = (optionLength / MAX_DISPLAY_LINES).ceil();
    initializingState = false;
    initializedState = true;
    // TODO: implement initState
  }

}