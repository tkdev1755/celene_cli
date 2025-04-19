import 'dart:ffi';
import 'package:celene_cli/model/KeychainAPI/keyring.dart';
import 'package:celene_cli/model/extensions.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

typedef CStorePassword = Int32 Function(Pointer<Utf8>, Pointer<Utf8>);
typedef CGetPassword = Pointer<Utf8> Function(Pointer<Utf8>);
typedef CFreePassword = Void Function(Pointer<Utf8>);

typedef DartStorePassword = int Function(Pointer<Utf8>, Pointer<Utf8>);
typedef DartGetPassword = Pointer<Utf8> Function(Pointer<Utf8>);
typedef DartFreePassword = void Function(Pointer<Utf8>);

class LinuxKeychainBindings extends KeyringBase {
  late final DartStorePassword _storePassword;
  late final DartGetPassword _getPassword;
  late final DartFreePassword _freePassword;

  LinuxKeychainBindings() {
    final _lib = DynamicLibrary.open(path.join('${BASEDIR}libkeychain.so'));

    _storePassword = _lib
        .lookup<NativeFunction<CStorePassword>>('store_password')
        .asFunction();

    _getPassword = _lib
        .lookup<NativeFunction<CGetPassword>>('get_password')
        .asFunction();

    _freePassword = _lib
        .lookup<NativeFunction<CFreePassword>>('free_password')
        .asFunction();
  }



  @override
  int addPassword(String account, String service, String password) {
    final keyPtr = account.toNativeUtf8();
    final passwordPtr = password.toNativeUtf8();

    final result = _storePassword(keyPtr, passwordPtr);

    malloc.free(keyPtr);
    malloc.free(passwordPtr);

    return result;
  }

  @override
  String? readPassword(String account, String service) {
    final keyPtr = account.toNativeUtf8();
    final resultPtr = _getPassword(keyPtr);
    malloc.free(keyPtr);
    if (resultPtr == nullptr) return null;

    final result = resultPtr.toDartString();
    _freePassword(resultPtr);
    return result;
  }
}