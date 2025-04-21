
import 'dart:io';

import 'package:celene_cli/model/celeneObject.dart';
import 'package:celene_cli/view/view.dart';
import 'package:dart_console/dart_console.dart';

class ImportClassesView extends View{
  List<Classes> options = [];
  int selectedIndex = 0;
  int displayedSubList = 0;
  int maxSublists = 0;
  int optionLength = 0;
  bool loadingMessageDrawn = false;
  int realTerminalHeight = 0;
  static int MAX_DISPLAY_LINES = 5;

  ImportClassesView(super.controller, {super.parent}){
   realTerminalHeight = console.windowHeight - 4;
  }

  String askToRename(){
    console.writeLine('=== Écrit le nom du nouveau cours ===\n');
    console.writeLine('Nouveau nom :');
    String? result = stdin.readLineSync();
    if (result != null){
      return result;
    }
    else{
      return "";
    }
  }

  void drawLoadingScreen() {
    console.clearScreen();
    console.writeLine("----- Chargement du Cours -----");
    console.resetColorAttributes();
  }
  @override
  void draw() {
    MAX_DISPLAY_LINES = ((realTerminalHeight/2).floor())-5 > 5 ? ((realTerminalHeight/2).floor())-5 : 5 ;
    maxSublists = (optionLength / MAX_DISPLAY_LINES).ceil();
    int startIndex = (displayedSubList)*MAX_DISPLAY_LINES;
    int endIndex = (displayedSubList+1)*(MAX_DISPLAY_LINES);
    int displayEndIndex = endIndex < options.length ? endIndex : options.length;
    console.clearScreen();
    console.setForegroundColor(ConsoleColor.cyan);
    console.writeLine('=== Vérifie les cours qui ont été récupérés ===');
    console.resetColorAttributes();
    for (int i = startIndex; i < displayEndIndex; i++) {
      String textToWrite = '${options[i]}';
      if (i == selectedIndex) {
        console.setForegroundColor(ConsoleColor.black);
        console.setBackgroundColor(ConsoleColor.yellow);
        console.writeLine('> $textToWrite');
        console.resetColorAttributes();
        console.write("\n");
      } else {
        console.writeLine('  $textToWrite');
        console.write("\n");
      }
    }

    final linesToFill = realTerminalHeight - (MAX_DISPLAY_LINES*2)-2; // -2 pour marge et footer
    for (int i = 0; i < linesToFill; i++) {
      console.writeLine('');
    }
    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine('─' * console.windowWidth); // ligne de séparation

    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine('r : Renommer le cours   |   e : Effacer le cours   |   s : Sauvegarder les cours\no: Ouvrir le cours   |   esc : Quitter | ⌫ : Retour en arrière');

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
    else{
      switch (key.char){
        case 'r':
          print("Renommer");
          String newName = askToRename();
          controller.handleInput("renameCourse", (newName, selectedIndex));
          break;
        case 's':
          print("Sauvegarder les changement");
          controller.handleInput("saveChanges", null);
          break;
        case 'e':
          print("Effacer le cours");
          controller.handleInput("removeCourse", selectedIndex);
          break;
        case 'o':
          print("Ouvrir le cours");
          await controller.handleInput("openCourse", selectedIndex);
      }
    }
  }

  @override
  Future<void> initState()  async{
    initializingState = true;
    options = await controller.getData();
    optionLength = options.length;
    MAX_DISPLAY_LINES = ((realTerminalHeight/2).floor())-5 > 5 ? ((realTerminalHeight/2).floor())-5 : 5 ;
    maxSublists = (optionLength / MAX_DISPLAY_LINES).ceil();
    print("Finished getting options");
    initializingState = false;
    initializedState = true;
  }

  @override
  Future<void> run() async {
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
  }



}