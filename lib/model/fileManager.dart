
import 'dart:io';
import 'package:celene_cli/model/extensions.dart';
/// {@category USER-DATA}
/// Classe représentant un fichier téléchargé à partir d'une ressource sur celene
class FileEntry{
  /// Nom du fichier
  String name;
  /// Nom de la ressource sur celene à partir duquel le fichier à été téléchargé
  String entryName;
  /// Type du fichier (dossier ou fichier classique)
  String type;

  /// ID du cours associé à la ressource à partir duquel le fichier à été téléchargé
  String courseID;

  /// Indique si c'est le dernier cours qui a été téléchargé
  bool latest;

  /// Dans le cadre d'un fichier faisant parti d'un dossier, le nom du dossier parent
  String? parent;
  /// Dans le cadre d'un dossier, tout les fichiers appartenant au dossier
  List<FileEntry>? children;

  FileEntry(
      this.name,
      this.entryName,
      this.type,
      this.courseID,
      this.latest,
      {this.parent,
        this.children}
      );
  /// Fonction ouvrant le fichier associé dans l'application préférée par l'utilistaeur
  static Future<void> openFile(FileEntry file, {folder=false}) async {
    if (!Platform.isWindows){
      if (folder){
        print("Path is ${file.courseID}/${file.parent}/${file.name}");
        await Process.run("open", ["${BASEDIR}${file.courseID}/${file.parent}/${file.name}"]);
      }
      else{
        await Process.run("open", ["${BASEDIR}${file.courseID}/${file.name}"]);
      }
    }
    else{
      // IF ON WINDOWS open the file this way (because for some reason start is a better command to open files than open.)
      // a function which was 5 lines long became a function 25 lines long....
      if (folder){
        await Process.start(
          'cmd',
          ['/c', 'start', '', "$WIN_BASEDIR${file.courseID}\\${file.parent}\\${file.name}"],
          runInShell: true,
        );
      }
      else{
        await Process.start(
          'cmd',
          ['/c', 'start', '', "$WIN_BASEDIR${file.courseID}\\${file.name}"],
          runInShell: true,
        );
      }
    }
  }

  /// Fonction ouvrant un lien
  static Future<void> openLink(String link)async {
    if (Platform.isWindows){
      await Process.start(
        'cmd',
        ['/c', 'start', '', link],
        runInShell: true,
      );
    }
    else{
      await Process.run("open", [link]);
    }
  }
  /// Fonction d'affichage
  @override
  String toString() {
    return "Nom : ${name}, type : -${type}";
  }


}