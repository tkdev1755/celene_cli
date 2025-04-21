import 'dart:ffi';
import 'package:celene_cli/model/KeychainAPI/keyring.dart';
import 'package:celene_cli/model/extensions.dart';
import 'package:ffi/ffi.dart';
import 'dart:io';


// Définitions FFI
typedef SetPasswordC = Bool Function(
    Pointer<Utf16> targetName,
    Pointer<Utf16> username,
    Pointer<Utf16> password,
    );
typedef SetPasswordDart = bool Function(
    Pointer<Utf16> targetName,
    Pointer<Utf16> username,
    Pointer<Utf16> password,
    );

typedef ReadPasswordC = Bool Function(
    Pointer<Utf16> targetName,
    Pointer<Utf16> outPassword,
    Int32 maxLen,
    );
typedef ReadPasswordDart = bool Function(
    Pointer<Utf16> targetName,
    Pointer<Utf16> outPassword,
    int maxLen,
    );

/// {@category SAFETY}
/// Interface FFI (Foreign Function Interface) permettant d'intéragir avec une librairie dynamique C (Ici le Windows Credential Manager)
class WindowsKeychainBindings extends KeyringBase{
  static late final DynamicLibrary _lib;
  static late final SetPasswordDart _setPassword;
  static late final ReadPasswordDart _readPassword;

  WindowsKeychainBindings(){
    _lib = Platform.isWindows
        ? DynamicLibrary.open('${BASEDIR}libkeychain.dll')
        : throw UnsupportedError('Fonctionne uniquement sur Windows');

    _setPassword = _lib
        .lookupFunction<SetPasswordC, SetPasswordDart>('set_password');
    _readPassword = _lib
        .lookupFunction<ReadPasswordC, ReadPasswordDart>('read_password');
  }


  /// Enregistre un mot de passe
  ///
  @override
  int addPassword(String account, String service, String password) {
    final targetPtr = service.toNativeUtf16();
    final usernamePtr = account.toNativeUtf16();
    final passwordPtr = password.toNativeUtf16();

    final success = _setPassword(targetPtr, usernamePtr, passwordPtr);

    calloc.free(targetPtr);
    calloc.free(usernamePtr);
    calloc.free(passwordPtr);

    return success ? 0 : -1;
  }

  /// Lit un mot de passe
  @override
  String? readPassword(String account, String service) {
    int bufferSize = 2048;
    final targetPtr = service.toNativeUtf16();
    final outBuffer = calloc.allocate<Utf16>(bufferSize * 2); // UTF-16 = 2 bytes

    final success = _readPassword(targetPtr, outBuffer, bufferSize);

    String? password;
    if (success) {
      logger("successfully got the password");
      password = outBuffer.cast<Utf16>().toDartString();
      logger("Password is ${password}");
    }
    else{
      logger("No password found");
    }

    calloc.free(targetPtr);
    calloc.free(outBuffer);
    return password;
  }


}