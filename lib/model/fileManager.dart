
import 'dart:io';
import 'package:path/path.dart' as path;

class FileEntry{
  String name;
  String entryName;
  String type;
  String courseID;
  bool latest;
  String? parent;
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

  static Future<void> openFile(FileEntry file, {folder=false}) async {
    if (!Platform.isWindows){
      if (folder){
        print("Path is ${file.courseID}/${file.parent}/${file.name}");
        await Process.run("open", ["${file.courseID}/${file.parent}/${file.name}"]);
      }
      else{
        await Process.run("open", ["${file.courseID}/${file.name}"]);
      }
    }
    else{
      // IF ON WINDOWS open the file this way (because for some reason start is a better command to open files than open.)
      // a function which was 5 lines long became a function 25 lines long....
      if (folder){
        await Process.start(
          'cmd',
          ['/c', 'start', '', "${file.courseID}\\${file.parent}\\${file.name}"],
          runInShell: true,
        );
      }
      else{
        await Process.start(
          'cmd',
          ['/c', 'start', '', "${file.courseID}\\${file.name}"],
          runInShell: true,
        );
      }
    }
  }
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
  @override
  String toString() {
    return "Nom : ${name}, type : -${type}";
  }


}