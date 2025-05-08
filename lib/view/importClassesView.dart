
import 'dart:io';

import 'package:celene_cli/model/celeneObject.dart';
import 'package:celene_cli/view/view.dart';
import 'package:dart_console/dart_console.dart';

import '../model/extensions.dart';

class ImportClassesView extends View{
  List<Classes> options = [];
  List<int> sublistIndex= [];
  int selectedIndex = 0;
  int displayedSubList = 0;
  int optionLength = 0;
  bool loadingMessageDrawn = false;
  int displayedElements = 0;
  static int MAX_DISPLAY_LINES = 5;
  static String footerText = 'r : Renommer le cours   |   e : Effacer le cours   |   s : Sauvegarder les cours   |   o: Ouvrir le cours   |   esc : Quitter   |   ⌫ : Retour en arrière';
  static String headerText = '=== Vérifie les cours qui ont été importés ===';
  static String separator = '';
  int width = 0;
  int height = 0;
  ImportClassesView(super.controller, {super.parent}){
    width = console.windowWidth;
    height = console.windowHeight;
    separator = '─'*width;
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
    if (console.windowHeight != height || console.windowWidth != width) {
      height = console.windowHeight;
      width  = console.windowWidth;
      separator = '─'*width;
      _computeSublist();
    }
    displayedElements = 0;
    int availableLines = height;



    console.clearScreen();
    console.setForegroundColor(ConsoleColor.cyan);
    console.writeLine(headerText);
    availableLines -= (headerText.getLineUsed(width) + footerText.getLineUsed(width) + separator.getLineUsed(width));
    console.resetColorAttributes();
    int startIndex = sublistIndex[displayedSubList];
    int endIndex = displayedSubList == (sublistIndex.length)-1 ? optionLength: sublistIndex[displayedSubList+1];
    for (int i = startIndex; i < endIndex; i++) {
      String textToWrite = '${options[i]}';
      String textToDisplay = i == selectedIndex ? '> $textToWrite' : '  $textToWrite';

      if (i == selectedIndex) {
        console.setForegroundColor(ConsoleColor.black);
        console.setBackgroundColor(ConsoleColor.yellow);
        console.writeLine(textToDisplay);
        console.resetColorAttributes();
        console.write("\n");
      } else {
        console.writeLine(textToDisplay);
        console.write("\n");
      }
      availableLines -= textToDisplay.getLineUsed(console.windowWidth) + 1;
      displayedElements++;
      if (availableLines < 5){
        endIndex = i;
        // No more lines available to display text on terminal, so change displayEndIndex to this one
      }
    }

    for (int i = 0; i < availableLines-1; i++) {
      console.writeLine('');
    }
    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine(separator); // ligne de séparation

    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine(footerText);

  }

  @override
  Future<void> handleInput() async {
    int startIndex = sublistIndex[displayedSubList];
    int endIndex = (sublistIndex[displayedSubList]+displayedElements)-1;
    int displayEndIndex = endIndex < options.length ? endIndex : options.length;
    var key = await console.readKey();
    if (key.isControl) {
      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          if (selectedIndex == startIndex){
            if (selectedIndex == 0){
              displayedSubList = (sublistIndex.length-1);
            }
            else{
              displayedSubList--;
            }
          }
          selectedIndex = (selectedIndex - 1) % options.length;
          break;
        case ControlCharacter.arrowDown:
          if (selectedIndex == displayEndIndex){
            if (displayedSubList == (sublistIndex.length-1)){
              displayedSubList = 0;
            }
            else{
              displayedSubList += 1;
            }
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
          logger("Renommer");
          String newName = askToRename();
          controller.handleInput("renameCourse", (newName, selectedIndex));
          break;
        case 's':
          logger("Sauvegarder les changement");
          controller.handleInput("saveChanges", null);
          break;
        case 'e':
          logger("Effacer le cours");
          controller.handleInput("removeCourse", selectedIndex);
          break;
        case 'o':
          logger("Ouvrir le cours");
          await controller.handleInput("openCourse", selectedIndex);
      }
    }
  }

  @override
  Future<void> initState()  async{
    initializingState = true;
    options = await controller.getData();
    optionLength = options.length;
    _computeSublist();
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

  void _computeSublist(){
    sublistIndex.clear();
    int availableLines = height;
    int defaultTextLines = (headerText.getLineUsed(width)+footerText.getLineUsed(width)+separator.getLineUsed(width));
    availableLines -= defaultTextLines;
    sublistIndex.add(0);
    for (int i = 0; i<optionLength; i++){

      String textToWrite = '${options[i]}';
      String textToDisplay = i == selectedIndex ? '> $textToWrite' : '  $textToWrite';
      availableLines -= (textToDisplay.getLineUsed(width)+1);
      if (availableLines < 5){
        if (i < optionLength-1){
          sublistIndex.add(i+1);
        }
        availableLines = console.windowHeight-defaultTextLines;
      }
    }
  }



}