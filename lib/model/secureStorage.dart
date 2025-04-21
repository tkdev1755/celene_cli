

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:celene_cli/model/extensions.dart';
import 'package:encrypt/encrypt.dart';
/// {@category SAFETY}
/// Classe stockant les informations de session de l'utilisateur de manière sécurisée
class SecureStorage{
  /// Attribut représentant les données déchiffrées
  Map<String, String> _data = {};
  /// Clé de chiffrement du SecureStorage
  String? _secureStorageKey;
  /// Objet Key représentant la clé de chiffrement du SecureStorage
  late Key? _encryptedSecureStorageKey;
  /// Clé de chiffrement (IV) du SecureStorage
  IV? _secureStorageIV;
  /// Indique si le SecureStorage est activé (Si l'utilisateur à choisi d'activer la persistance de session)
  bool _secureStorageStatus = false;

  /// Indique si le SecureStorage a été correctement déchiffré et a été lu correctement
  bool _secureStorageReadStatus = false;
  /// Chemin de stocakge du secureStorage
  String SECURE_STORAGE_PATH = "${BASEDIR}secStorage.key";

  /// Header de debugage
  static String secStorageInitDebugHeader = "[SecureStorage - loadSecureStorage]";
  /// Header de debugage
  static String dumpDebugHeader = "[SecureStorage - Dump]";
  /// Objet Encrypter permettant le chiffrement des données
  late Encrypter? _encrypter;

  SecureStorage(this._secureStorageStatus,this._secureStorageKey,this._secureStorageIV){
      if (_secureStorageStatus){
        _secureStorageReadStatus = loadSecureStorage();
      }
  }

  /// Fonction permettant le chargement et déchiffrement du SecureStorage
  bool loadSecureStorage(){
    logger("$secStorageInitDebugHeader - SecureStorage was set");
    if (_secureStorageKey == null || _secureStorageIV == null){
      // TODO - Add better error handling
      throw Exception("Secure storage was marked as set but no marks of it on the host system");
    }
    else{
      _encryptedSecureStorageKey = Key.fromUtf8(_secureStorageKey!);
      _encrypter = Encrypter(AES(_encryptedSecureStorageKey!));
      File storageFile = File(SECURE_STORAGE_PATH);
      if (!storageFile.existsSync()){
        logger("$secStorageInitDebugHeader -  key file does not exist, creating it");
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
        logger("$secStorageInitDebugHeader - Data resssemble to this ${_data}");
        return true;
      }
    }
  }
  /// Fonction permettant de chiffrer le SecureStorage et d'écrire le fichier chiffré sur le disque
  Future<bool> dump() async{
    if (!_secureStorageReadStatus){
      logger("$dumpDebugHeader - FALSE RETURN : SecureStorage was correctly initialized but data from file wasn't correctly parsed");
      return false;
    }
    if (_secureStorageIV == null || _secureStorageKey == null || _encrypter == null || _encryptedSecureStorageKey == null){
      logger("$dumpDebugHeader - FALSE RETURN : Either _secureStorageIV || _secureStorageKey || _encrypter || _encryptedSecureStorageKey was null, here is the result");
      logger("$dumpDebugHeader - FALSE RETURN : $_secureStorageIV || $_secureStorageKey || $_encrypter || $_encryptedSecureStorageKey");
      return false;
    }
    Encrypted encrypted = _encrypter!.encrypt(jsonEncode(_data), iv: _secureStorageIV);

    File encryptedFile = File(SECURE_STORAGE_PATH);

    await encryptedFile.writeAsBytes(encrypted.bytes);

    return true;
  }

  /// Fonction permettant de savoir si le SecureStorage à été correctement initialisé
  bool getSecureStorageStatus(){
    return _secureStorageReadStatus;
  }

  /// Fonction permettant d'obtenir la valeur d'une clé du SecureStorage
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

  /// Fonction permettant d'attribuer une valeur à une clé au sein du SecureStorage
  void setValue(String key, String value){
    if (_secureStorageReadStatus && _secureStorageStatus){
      logger("$secStorageInitDebugHeader - setValue : setting key $key on value $value");
      _data[key] = value;
    }
    else{
      throw Exception("SecureStorage function called when no secure storage was set");
    }
  }

}