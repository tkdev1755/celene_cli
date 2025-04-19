

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:celene_cli/model/extensions.dart';
import 'package:encrypt/encrypt.dart';

class SecureStorage{

  Map<String, String> _data = {};

  String? _secureStorageKey;
  late Key? _encryptedSecureStorageKey;
  IV? _secureStorageIV;
  bool _secureStorageStatus = false;
  bool _secureStorageReadStatus = false;
  String SECURE_STORAGE_PATH = "${BASEDIR}secStorage.key";

  static String secStorageInitDebugHeader = "[SecureStorage - loadSecureStorage]";
  static String dumpDebugHeader = "[SecureStorage - Dump]";

  late Encrypter? _encrypter;
  SecureStorage(this._secureStorageStatus,this._secureStorageKey,this._secureStorageIV){
      if (_secureStorageStatus){
        _secureStorageReadStatus = loadSecureStorage();
      }
  }

  bool loadSecureStorage(){
    print("$secStorageInitDebugHeader - SecureStorage was set");
    if (_secureStorageKey == null || _secureStorageIV == null){
      // TODO - Add better error handling
      throw Exception("Secure storage was marked as set but no marks of it on the host system");
    }
    else{
      _encryptedSecureStorageKey = Key.fromUtf8(_secureStorageKey!);
      _encrypter = Encrypter(AES(_encryptedSecureStorageKey!));
      File storageFile = File(SECURE_STORAGE_PATH);
      if (!storageFile.existsSync()){
        print("$secStorageInitDebugHeader -  key file does not exist, creating it");
        storageFile.createSync();
        _data = {};
        return true;
      }
      else{
        storageFile.openRead();
        Uint8List encryptedContent = storageFile.readAsBytesSync();
        if (encryptedContent.isEmpty){
          _secureStorageReadStatus  = true;
          return true;
        }
        String data = utf8.decode(_encrypter!.decryptBytes(Encrypted(encryptedContent), iv: _secureStorageIV!));
        Map<String,dynamic> res = jsonDecode(data);
        _secureStorageReadStatus  = true;
        _data = res.cast();
        print("$secStorageInitDebugHeader - Data resssemble to this ${_data}");
        return true;
      }
    }
  }

  Future<bool> dump() async{
    if (!_secureStorageReadStatus){
      print("$dumpDebugHeader - FALSE RETURN : SecureStorage was correctly initialized but data from file wasn't correctly parsed");
      return false;
    }
    if (_secureStorageIV == null || _secureStorageKey == null || _encrypter == null || _encryptedSecureStorageKey == null){
      print("$dumpDebugHeader - FALSE RETURN : Either _secureStorageIV || _secureStorageKey || _encrypter || _encryptedSecureStorageKey was null, here is the result");
      print("$dumpDebugHeader - FALSE RETURN : $_secureStorageIV || $_secureStorageKey || $_encrypter || $_encryptedSecureStorageKey");
      return false;
    }
    Encrypted encrypted = _encrypter!.encrypt(jsonEncode(_data), iv: _secureStorageIV);

    File encryptedFile = File(SECURE_STORAGE_PATH);

    await encryptedFile.writeAsBytes(encrypted.bytes);

    return true;
  }
  bool getSecureStorageStatus(){
    return _secureStorageReadStatus;
  }

  String? getValue(String key){
    if (_secureStorageReadStatus && _secureStorageStatus){
      if (_data.containsKey(key)) {
        return _data[key]!;
      } else {
        return null;
      }
    }
    else{
      throw Exception("SecureStorage function called when no secure storage was set");
    }
  }

  void setValue(String key, String value){
    if (_secureStorageReadStatus && _secureStorageStatus){
      print("$secStorageInitDebugHeader - setValue : setting key $key on value $value");
      _data[key] = value;
    }
    else{
      throw Exception("SecureStorage function called when no secure storage was set");
    }
  }

}