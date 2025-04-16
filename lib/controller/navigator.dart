

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:celene_cli/controller/controller.dart';
import 'package:celene_cli/view/view.dart';

class Navigator{

  View? currentView;
  bool initializedView = false;


  Future<void> display() async{
    if (initializedView){
      await currentView!.run();
    }
  }


  void setView(View view){
    currentView = view;
    initializedView=  true;
  }
  void push(View newView){
    initializedView = false;
    currentView = newView;
    initializedView = true;
  }

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

  static void exitProgram(){
    // Do cleanup tasks
    exit(0);
  }




}