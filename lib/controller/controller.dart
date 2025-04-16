

import '../view/view.dart';

abstract class Controller{
  Map<String,bool> flags = {};

  handleInput(String type,dynamic data,{View? parent});

  getData();

  setData(dynamic data);

  bool getFlag(String flag);
  setFlag(String flag);

  quitApp();

}