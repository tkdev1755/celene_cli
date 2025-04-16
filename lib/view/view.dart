

import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/view/chooseCourseView.dart';
import 'package:dart_console/dart_console.dart';

abstract class View{
  final console = Console();
  Controller controller;
  View? parent;
  bool initializedState = false;
  bool initializingState = false;
  View(this.controller,{this.parent});

  Future<void> run();

  void draw();

  // Function to call if data was updated and changes have to be displayed on the parent page when going back to it
  void updateData(){
    initializedState = false;
  }
  Future<void> handleInput();

  Future<void> initState();
}