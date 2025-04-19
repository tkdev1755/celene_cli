

import '../view/view.dart';
/// Classe Controlleur agissant en tant qu'intermédiaire entre le modèle et la vue
abstract class Controller{
  /// Drapeaux en fonction de la page associée
  Map<String,bool> flags = {};
  /// Fonction recevant l'entrée transmise par la vue et traitant cette entrée en appelant les fonctions nécessaires
  handleInput(String type,dynamic data,{View? parent});

  /// Fonction récupérant les données demandées par la vue auprès du modèle
  getData();

  /// Fonction modifiant les données du modèles en fonction de la vue
  setData(dynamic data);

  /// Fonction renvoyant l'état d'un drapeau en particulier
  bool getFlag(String flag);

  /// Fonction modifiant un drapeau en particulier
  setFlag(String flag);

  /// Fonction gérant la fermeture de l'application en cas d'appui sur CTRL+C ou ESC
  quitApp();

}