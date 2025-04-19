

import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/view/chooseCourseView.dart';
import 'package:dart_console/dart_console.dart';

/// Classe abstraite représentant une vue affichée à l'écran
abstract class View{

  /// Objet console permettant de contrôler l'affichage du terminal
  final console = Console();

  /// Objet controller pour obtenir les données nécessaire à l'affichage
  Controller controller;

  /// Vue parent depuis laquelle la vue a été affichée (si null, pas de vue Parent)
  View? parent;

  /// Variable représentant si la vue a été correctement initialisée
  bool initializedState = false;

  /// Variable représentant si la vue est en train d'être initialisée
  bool initializingState = false;
  View(this.controller,{this.parent});

  /// Fonction appelée par Navigator.display(), combine affichage et gestion des entrées
  Future<void> run();

  /// Fonction chargée de l'affichage sur le terminal
  void draw();

  // Function to call if data was updated and changes have to be displayed on the parent page when going back to it
  /// Fonction permettant de mettre à jour l'affichage si des changements sont à déployer
  void updateData(){
    initializedState = false;
  }
  /// Fonction permettant de gérer l'entrée de l'utilisateur
  Future<void> handleInput();
  /// Fonction d'initialisation de la vue
  Future<void> initState();
}