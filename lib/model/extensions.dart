import 'dart:io';

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

String BASEDIR = !Platform.isWindows ? "~/celeneCLI/" : "${Platform.environment['USERPROFILE']}/celeneCLI/";
String WIN_BASEDIR = Platform.isWindows ? "${Platform.environment['USERPROFILE']}\\celeneCLI\\" : "";