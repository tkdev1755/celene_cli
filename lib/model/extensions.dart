import 'dart:io';
/// Extension permettant d'obtenir un parsing des Records (tuples) comme en python
extension RecordIndexing<T1, T2> on (T1, T2) {
  dynamic operator [](int index) {
    switch (index) {
      case 0:
        return this.$1;
      case 1:
        return this.$2;
      default:
        throw RangeError("Invalid index $index for a record of length 2.");
    }
  }

}
/// Extension permettant d'obtenir un parsing des Records (tuples) comme en python
extension RecordIndexing2<T1, T2,T3> on (T1, T2,T3) {
  dynamic operator [](int index) {
    switch (index) {
      case 0:
        return this.$1;
      case 1:
        return this.$2;
      case 2:
        return this.$3;
      default:
        throw RangeError("Invalid index $index for a record of length 2.");
    }
  }

}

extension ObjectLines on Object{
  int getLineUsed(int width){
    double lineUsed = (this.toString().length/width);
    return lineUsed <= 1 ? 1 : (lineUsed.ceil());
  }
}

String BASEDIR = !Platform.isWindows ? "${Platform.environment['HOME']}/celeneCLI/" : "${Platform.environment['USERPROFILE']}/celeneCLI/";
String WIN_BASEDIR = Platform.isWindows ? "${Platform.environment['USERPROFILE']}\\celeneCLI\\" : "";
bool DEBUG = true;

void logger(dynamic content){
  if (DEBUG){
    print(content.toString());
  }
}