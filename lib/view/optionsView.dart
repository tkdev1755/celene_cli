

import 'package:celene_cli/model/extensions.dart';
import 'package:celene_cli/view/view.dart';
import 'package:dart_console/dart_console.dart';

class OptionsView extends View{
  List<(String,String)> options = [];
  int selectedIndex = 0;
  int optionLength = 0;

  OptionsView(super.controller, {super.parent});

  @override
  void draw() async {
    console.clearScreen();
    int width = console.windowWidth;
    int availableLines = console.windowHeight;
    console.setForegroundColor(ConsoleColor.cyan);
    console.setForegroundColor(ConsoleColor.cyan);
    String selectText = '=== Réglages ===';
    String optionsText = 'esc : Quitter | ⌫ : Retour en arrière';
    availableLines -= (selectText.getLineUsed(width) + optionsText.getLineUsed(width)+2);
    console.writeLine(selectText);
    console.resetColorAttributes();

    for (int i = 0; i < optionLength ; i++){
      if (i == selectedIndex){
        console.setForegroundColor(ConsoleColor.black);
        console.setBackgroundColor(ConsoleColor.yellow);
        console.writeLine(options[i][0]);
        console.resetColorAttributes();
      }
      else{
        console.writeLine(options[i][0]);
        console.resetColorAttributes();
      }
      availableLines --;
    }
    for (int i = 0; i < availableLines; i++){
      console.writeLine('');
    }
    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine('─' * console.windowWidth); // ligne de séparation
    console.setForegroundColor(ConsoleColor.brightCyan);
    console.writeLine(optionsText);
  }

  @override
  Future<void> handleInput() async {
    var key = await console.readKey();
    if (key.isControl){
      switch (key.controlChar){
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
          await controller.handleInput("exit", null);
          break;
        case ControlCharacter.enter:
          initializedState = (await controller.handleInput(options[selectedIndex][1],selectedIndex,parent: this) as bool?) ?? true;
          logger("InitState res = ${initializedState}");
          break;
        case ControlCharacter.escape:
          await controller.handleInput("exit", null);
          break;
        case ControlCharacter.backspace:
          controller.handleInput("return", null);
          break;
        default:
          // Ignorer les autres touches
          break;
      }
    }
    else{

    }
  }

  @override
  Future<void> initState() async{
    options = await controller.getData();
    optionLength = options.length;
    initializedState = true;
  }

  @override
  Future<void> run() async {
    if (!initializedState){
      logger("NEED TO LOAD");
      await initState();
    }
    draw();
    await handleInput();
  }

}