
import 'package:celene_cli/view/view.dart';
import 'package:dart_console/dart_console.dart';

import '../model/extensions.dart';




class ChooseCourseView extends View{

  List<String> options = [];
  int selectedIndex = 0;
  int displayedSubList = 0;
  int maxSublists = 0;
  int optionLength = 0;
  int displayedElements = 0;
  static int MAX_DISPLAY_LINES = 5;

  ChooseCourseView(super.controller,{super.parent});



  @override
  void draw() {
    displayedElements = 0;
    int width = console.windowWidth;
    int availableLines = console.windowHeight;

    int startIndex = (displayedSubList)*MAX_DISPLAY_LINES;
    int endIndex = (displayedSubList+1)*(MAX_DISPLAY_LINES);
    int displayEndIndex = endIndex < options.length ? endIndex : options.length;
    console.clearScreen();
    console.setForegroundColor(ConsoleColor.cyan);
    String titleText = '=== Menu Principal ===';
    String footerText = 'n : Ajouter un cours   |   e : Éditer les cours   |   r : Rechercher \ni: Importer les cours depuis Celene | esc : Quitter';
    console.writeLine(titleText);
    availableLines -= (titleText.getLineUsed(width) + footerText.getLineUsed(width) +2);
    console.resetColorAttributes();
    for (int i = startIndex; i < displayEndIndex; i++) {
      String lineText = i == selectedIndex ? '> ${options[i]}': '  ${options[i]}';
      if (i == selectedIndex) {
        console.setForegroundColor(ConsoleColor.black);
        console.setBackgroundColor(ConsoleColor.yellow);
        console.writeLine(lineText);
        console.resetColorAttributes();
      } else {
        console.writeLine(lineText);
      }
      availableLines -= lineText.getLineUsed(width);
      displayedElements++;
      if (availableLines == 0){
        // No more lines available to display text on terminal, so change displayEndIndex to the last line printed on screen to finish the loop
        displayEndIndex = i;
      }
    }
    for (int i = 0; i < availableLines; i++) {
      console.writeLine('');
    }

    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine('─' * console.windowWidth); // ligne de séparation
    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine(footerText);
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
    int displayEndIndex = endIndex < options.length ? endIndex : options.length;
    var key = await console.readKey();
    if (key.isControl) {
      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          if (options.isNotEmpty){
            if (selectedIndex == startIndex){
              displayedSubList = (displayedSubList -1) % maxSublists;
            }
            selectedIndex = (selectedIndex - 1) % options.length;
          }
          break;
        case ControlCharacter.arrowDown:
          if (options.isNotEmpty){
            if (selectedIndex+1 == displayEndIndex){
              displayedSubList = (displayedSubList +1) % maxSublists;
            }
            selectedIndex = (selectedIndex + 1) % options.length;
          }
          break;
        case ControlCharacter.ctrlC:
          controller.handleInput("exit", null);
          break;
        case ControlCharacter.enter:
          controller.handleInput("openCourse",selectedIndex,parent: this);
          break;
        case ControlCharacter.escape:
          controller.handleInput("exit", null);
          break;
        default:
        // Ignorer les autres touches
          break;
      }
    }
    else{
      logger("Detected other input than controlCharacter");
      switch(key.char){
        case 'n':
          logger("Adding course");
          controller.handleInput("addCourse",null,parent: this);
          break;
        case 'e':
          controller.handleInput("editCourses", null);
          break;
        case 'r':
          controller.handleInput("searchCourse", null);
          break;
        case 'i':
          controller.handleInput("importClasses", null, parent: this);
      }
    }
  }

  @override
  Future<void> run() async {
    if (!initializedState){
      initState();
    }
    draw();
    await handleInput();
    // TODO: implement run
  }

  @override
  Future<void> initState() async {
    options = super.controller.getData() as List<String>;
    optionLength = options.length;
    MAX_DISPLAY_LINES = console.windowHeight-10 > 5 ? console.windowHeight-10 : 5 ;
    maxSublists = (optionLength / MAX_DISPLAY_LINES).ceil();
    initializedState = true;
    // TODO: implement initState
  }
}
