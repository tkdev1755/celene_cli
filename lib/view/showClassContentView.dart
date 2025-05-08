

import 'package:celene_cli/model/extensions.dart';
import 'package:celene_cli/view/view.dart';
import '../model/celeneObject.dart';
import 'package:dart_console/dart_console.dart';

class ShowClassContentView extends View {
  List<Course> options = [];
  List<(int,int)> optionSize =[];
  List<int> sublistIndex= [];
  int selectedIndex = 0;
  bool loadingMessageDrawn = false;
  int displayedSubList = 0;
  int optionLength = 0;
  int displayedElements = 0;
  static String footerText = '⏎ : Télécharger/Ouvrir la ressource   |   o : Ouvrir le dossier de la ressource  |  r : Rechercher  |   esc : Quitter | ⌫ : Retour en arrière';
  static String headerText = '=== Sélectionne un cours à télécharger/ouvrir ===';
  String separator = '';
  int width = 0;
  int height = 0;

  ShowClassContentView(super.controller,{super.parent}){
    width = console.windowWidth;
    height = console.windowHeight;
    separator = '─'*width;
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
    if (controller.getFlag("downloadCourse")){
      return;
    }
    console.clearScreen();
    console.setForegroundColor(ConsoleColor.cyan);
    console.writeLine(headerText);
    availableLines -= (headerText.getLineUsed(width) + footerText.getLineUsed(width) + separator.getLineUsed(width));
    console.resetColorAttributes();
    int startIndex = sublistIndex[displayedSubList];
    int endIndex = displayedSubList == (sublistIndex.length)-1 ? optionLength: sublistIndex[displayedSubList+1];
    for (int i = startIndex; i < endIndex; i++) {
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
      if (availableLines < 5){
        endIndex = i;
        // No more lines available to display text on terminal, so change displayEndIndex to this one
      }
    }
    //final linesToFill = realTerminalHeight - (MAX_DISPLAY_LINES*2)-2; // -2 pour marge et footer
    for (int i = 0; i < availableLines-1; i++) {
      console.writeLine('');
    }
    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine(separator); // ligne de séparation
    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine(footerText);
  }

  void drawLoadingScreen(){
    console.clearScreen();
    console.writeLine("----- Chargement du Cours -----");
    console.resetColorAttributes();
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

  void _computeSublist(){
    sublistIndex.clear();
    int availableLines = height;
    int defaultTextLines = (headerText.getLineUsed(width)+footerText.getLineUsed(width)+separator.getLineUsed(width));
    availableLines -= defaultTextLines;
    sublistIndex.add(0);
    for (int i = 0; i<optionLength; i++){

      String textToWrite = options[i].downloaded ? '${options[i]} (Téléchargé)' : '${options[i]}';
      String textToDisplay = i == selectedIndex ? '>$textToWrite' : ' $textToWrite';
      availableLines -= (textToDisplay.getLineUsed(width)+1);
      if (availableLines < 5){
        if (i < optionLength-1){
          sublistIndex.add(i+1);
        }
        availableLines = console.windowHeight-defaultTextLines;
      }
    }
  }

  @override
  Future<void> initState() async{
    initializingState = true;
    options = await super.controller.getData() as List<Course>;
    optionLength = options.length;
    _computeSublist();
    initializingState = false;
    initializedState = true;
    // TODO: implement initState
  }

}