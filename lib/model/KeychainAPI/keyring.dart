import 'dart:io';
import 'package:celene_cli/model/KeychainAPI/linux/linuxKeychainAPI.dart';
import 'package:celene_cli/model/KeychainAPI/windows/windowsKeychainAPI.dart';

import 'macos/macOSKeychainAPI.dart';

abstract class KeyringBase{

  int addPassword(String account, String service, String password);

  String? readPassword(String account, String service);
}

/// Interface unifiée pour accéder au trousseau de clés
class Keyring {

  KeyringBase? base;

  Keyring(){
    if (Platform.isMacOS){
      base = MacOSKeychainBindings();
    }
    else if (Platform.isLinux){
      base = LinuxKeychainBindings();
    }
    else if (Platform.isWindows){
      base = WindowsKeychainBindings();
    }
  }

  String? getPassword(String service, String username){
    if (base == null){
      print("Base isn't initialized");
      return null;
    }
    String? password  = base?.readPassword(username, service);
    return password;
  }

  int setPassword(String serviceName, String username, String password){
    if (base == null){
      print("KeyringBase isn't initialized properly");
      return -1;
    }
    int? result = base?.addPassword(username, serviceName, password);
    return result ?? -1;
  }

}