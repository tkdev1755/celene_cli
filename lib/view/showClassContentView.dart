import 'dart:io';

import 'package:celene_cli/model/extensions.dart';
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
  int predDisplayedElement = 0;
  int displayedElements = 0;
  int sublistStartIndex = 0;
  static int MAX_DISPLAY_LINES = 5;
  ShowClassContentView(super.controller,{super.parent});


  @override
  void draw() {
    displayedElements = 0;
    int width = console.windowWidth;
    int availableLines = console.windowHeight;

    if (controller.getFlag("downloadCourse")){
      return;
    }

    int startIndex = sublistStartIndex;
    int displayEndIndex = optionLength;

    console.clearScreen();
    console.setForegroundColor(ConsoleColor.cyan);
    String selectText = '=== Selectionne le fichier à télécharger/ouvrir ===';
    String optionsText = '⏎ : Télécharger/Ouvrir la ressource   |   o : Ouvrir le dossier de la ressource  \nr : Rechercher  |   esc : Quitter | ⌫ : Retour en arrière';
    console.writeLine(selectText);
    availableLines -= (selectText.getLineUsed(width) + optionsText.getLineUsed(width) +5); // +5 lines for debugging purposes
    console.resetColorAttributes();
    //logger("dslist : $displayedSubList, maxSlist = $maxSublists, sStartIndex = $sublistStartIndex,startIndex = $startIndex, endindex = $displayEndIndex, selectedIndex = $selectedIndex,predDisplayedElement = $predDisplayedElement, displayedElements = $displayedElements"); lines used for debugging
    for (int i = startIndex; i < displayEndIndex; i++) {
      String textToWrite = options[i].downloaded ? '${options[i]} (Téléchargé)' : '${options[i]}';
      String textToDisplay = i == selectedIndex ? '>$textToWrite' : ' $textToWrite';
      if (i == selectedIndex) {
        ConsoleColor dLSelectedColor = options[i].downloaded ? ConsoleColor.green : ConsoleColor.yellow;
        console.setForegroundColor(ConsoleColor.black);
        console.setBackgroundColor(dLSelectedColor);
        console.writeLine(textToDisplay);
        console.resetColorAttributes();
        console.write("\n");
      } else {
        console.writeLine(textToDisplay);
        console.resetColorAttributes();
        console.write("\n");
      }
      availableLines -= textToDisplay.getLineUsed(console.windowWidth) + 1;
      displayedElements++;
      if (availableLines <= 1){
        // No more lines available to display text on terminal, so change displayEndIndex to this one
        displayEndIndex = i;
      }
    }
    //final linesToFill = realTerminalHeight - (MAX_DISPLAY_LINES*2)-2; // -2 pour marge et footer
    for (int i = 0; i < availableLines; i++) {
      console.writeLine('');
    }
    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine('─' * console.windowWidth); // ligne de séparation
    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine(optionsText);
  }

  void drawLoadingScreen(){
    console.clearScreen();
    console.writeLine("----- Chargement du Cours -----");
    console.resetColorAttributes();
  }

  @override
  Future<void> handleInput() async {

    int startIndex = (displayedSubList)*displayedElements;
    int endIndex = (displayedSubList+1)*(displayedElements);
    if (displayedSubList == maxSublists-1){
      startIndex = optionLength - displayedElements;
      endIndex = optionLength;
    }
    sublistStartIndex = startIndex;
    int displayEndIndex = endIndex < options.length ? endIndex : options.length;
    // logger("dslist : $displayedSubList, maxSlist = $maxSublists, sStartIndex = $sublistStartIndex,startIndex = $startIndex, endindex = $displayEndIndex, predDisplayedElement = $predDisplayedElement, displayedElements = $displayedElements"); Lines used for debugging
    var key = await console.readKey();
    if (key.isControl) {
      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          if (selectedIndex == startIndex){
            displayedSubList = (displayedSubList -1) % maxSublists;
            if (selectedIndex == 0){
              sublistStartIndex = optionLength - predDisplayedElement;
            }
            else{
              sublistStartIndex = (startIndex - predDisplayedElement);
            }
            predDisplayedElement = displayedElements;
          }
          selectedIndex = (selectedIndex - 1) % options.length;
          break;
        case ControlCharacter.arrowDown:
          if (selectedIndex+1 == displayEndIndex){
            displayedSubList = (displayedSubList +1) % maxSublists;
            sublistStartIndex = endIndex;
            if (selectedIndex == optionLength-1){
              sublistStartIndex = 0;
            }
            predDisplayedElement = displayedElements;

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
    else{
      switch (key.char){
        case 'o':
          logger("Opening course in file explorer");
          await controller.handleInput("openCourseFE", selectedIndex, parent: this);
        case 'r':
          logger("Research !");
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