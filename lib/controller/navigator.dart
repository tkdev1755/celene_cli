

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/view/view.dart';
/// Fonction gérant l'affichage à l'écran et la navigation entre différentes pages
class Navigator{
  /// Vue qui sera affichée si this.display() est appelée
  View? currentView;
  /// Indique si une vue à été correctement initialisée
  bool initializedView = false;

  /// Fonction affichant le résultat d'une vue à l'écran
  Future<void> display() async{
    if (initializedView){
      await currentView!.run();
    }
  }

  /// Fonction permettant d'initialiser la vue à afficher
  void setView(View view){
    currentView = view;
    initializedView=  true;
  }

  /// Fonction permettant de naviguer vers une nouvelle vue, en mettant l'ancienne vue en tant que parent de la nouvelle
  void push(View newView){
    initializedView = false;
    currentView = newView;
    initializedView = true;
  }
  /// Fonction permettant de revenir en arrière dans l'affichage des vues
  void pop(){
    initializedView = false;
    if (currentView != null){
      if (currentView?.parent != null){
        currentView!.parent!.updateData();
        currentView = currentView!.parent;
      }
      else{
        throw Exception("Impossible to get to previous page");
      }
      initializedView = true;
    }
    else{
      throw Exception("Impossible to get to previous page");
    }
  }

  /// Ferme le programme correctement
  static void exitProgram(){
    // Do cleanup tasks
    exit(0);
  }

}