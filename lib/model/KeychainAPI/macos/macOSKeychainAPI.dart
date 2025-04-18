import 'dart:ffi';
import 'dart:io';
import 'package:celene_cli/model/KeychainAPI/keyring.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

typedef CAddPassword = Int32 Function(
    Pointer<Utf8> account,
    Pointer<Utf8> service,
    Pointer<Utf8> password,
    );

typedef DartAddPassword = int Function(
    Pointer<Utf8> account,
    Pointer<Utf8> service,
    Pointer<Utf8> password,
    );
typedef CReadPassword = Pointer<Utf8> Function(
    Pointer<Utf8> account,
    Pointer<Utf8> service,
    );

typedef DartReadPassword = Pointer<Utf8> Function(
    Pointer<Utf8> account,
    Pointer<Utf8> service,
    );

typedef CFreePassword = Void Function(Pointer<Utf8>);
typedef DartFreePassword = void Function(Pointer<Utf8>);

class MacOSKeychainBindings extends KeyringBase{

  late final DynamicLibrary _lib;
  late final DartAddPassword _addPassword;
  late final DartReadPassword _readPassword;
  late final DartFreePassword _freePassword;

  MacOSKeychainBindings() {
    final libPath = Platform.isMacOS ? path.join('libkeychain.dylib')
    : throw UnsupportedError("macOS only");
    _lib = DynamicLibrary.open(libPath);

    _addPassword = _lib
        .lookup<NativeFunction<CAddPassword>>('add_password')
        .asFunction();

    _readPassword = _lib
        .lookup<NativeFunction<CReadPassword>>('read_password')
        .asFunction();

    _freePassword = _lib
        .lookup<NativeFunction<CFreePassword>>('free_password')
        .asFunction();
  }

  @override
  int addPassword(String account, String service, String password) {
    final accountPtr = account.toNativeUtf8();
    final servicePtr = service.toNativeUtf8();
    final passwordPtr = password.toNativeUtf8();

    final result = _addPassword(accountPtr, servicePtr, passwordPtr);
    print("Added password with result : $result");
    malloc.free(accountPtr);
    malloc.free(servicePtr);
    malloc.free(passwordPtr);

    return result;
  }

  @override
  String? readPassword(String account, String service) {
    final acc = account.toNativeUtf8();
    final srv = service.toNativeUtf8();

    final ptr = _readPassword(acc, srv);
    malloc.free(acc);
    malloc.free(srv);
    print("ptr is ${ptr}");
    if (ptr.address == 0) return null;
    final result = ptr.toDartString();
    _freePassword(ptr);

    return result;
  }
}