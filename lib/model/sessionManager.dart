
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';



class SessionManager {

  Map<String, String>  _cookies = {};

  SessionManager();

  void updateCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      final cookies = setCookie.split(',');
      for (var cookie in cookies) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) {
          _cookies[parts[0].trim()] = parts[1].trim();
        }
      }
    }
  }

  void updateCookiesFromStreamResponse(http.StreamedResponse response){
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      final cookies = setCookie.split(',');
      for (var cookie in cookies) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) {
          _cookies[parts[0].trim()] = parts[1].trim();
        }
      }
    }
  }

  String generateCookieHeader() {
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }


  Map<String,String> getCookies(){
    return _cookies;
  }
  String? getCookieValue(String key){
    if (_cookies.containsKey(key)){
      return _cookies[key];
    }
    else{
      return null;
    }
  }

  void setCookie(String key, String value){
    _cookies[key] = value;
  }
}