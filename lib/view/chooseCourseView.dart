
import 'package:celene_cli/view/view.dart';
import 'package:dart_console/dart_console.dart';




class ChooseCourseView extends View{

  List<String> options = [];
  int selectedIndex = 0;

  ChooseCourseView(super.controller,{super.parent});



  @override
  void draw() {
    console.clearScreen();
    console.setForegroundColor(ConsoleColor.cyan);
    console.writeLine('=== Menu Principal ===');
    console.resetColorAttributes();
    for (int i = 0; i < options.length; i++) {
      if (i == selectedIndex) {
        console.setForegroundColor(ConsoleColor.black);
        console.setBackgroundColor(ConsoleColor.yellow);
        console.writeLine('> ${options[i]}');
        console.resetColorAttributes();
      } else {
        console.writeLine('  ${options[i]}');
      }
    }
    final terminalHeight = console.windowHeight;
    final currentLinesUsed = options.length + 1; // +1 pour le titre
    final linesToFill = terminalHeight - currentLinesUsed - 4; // -2 pour marge et footer

    for (int i = 0; i < linesToFill; i++) {
      console.writeLine('');
    }

    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine('─' * console.windowWidth); // ligne de séparation

    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine('n : Ajouter un cours   |   e : Éditer les cours   |   r : Rechercher \ni: Importer les cours depuis Celene | esc : Quitter');

    console.resetColorAttributes();

  }

  @override
  Future<void> handleInput() async {
    var key = await console.readKey();
    if (key.isControl) {
      switch (key.controlChar) {
        case ControlCharacter.arrowUp:
          if (options.isNotEmpty){
            selectedIndex = (selectedIndex - 1) % options.length;
          }
          break;
        case ControlCharacter.arrowDown:
          if (options.isNotEmpty){
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
      print("Detected other input than controlCharacter");
      switch(key.char){
        case 'n':
          print("Adding course");
          controller.handleInput("addCourse",null,parent: this);
          break;
        case 'e':
          controller.handleInput("editCourses", null);
          break;
        case 'r':
          controller.handleInput("searchCourse", null);
          break;
        case 'i':
          print("Importing courses");
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
    initializedState = true;
    // TODO: implement initState
  }
}
