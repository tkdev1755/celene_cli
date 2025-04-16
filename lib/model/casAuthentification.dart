import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:secure_session/secure_session.dart';
import 'package:encrypt/encrypt.dart';

import 'sessionManager.dart';
import 'package:http_session/http_session.dart';


Map<String, String> casServiceENUM = {
  "Celene" : "https%3A%2F%2Fcelene.insa-cvl.fr%2Flogin%2Findex.php"
};

class CASAuth{
  String SERVICE_PARAM = "?service=";
  String SECURE_STORAGE_PATH = "secureStorage.json";
  String casEndpoint = "https://cas.insa-cvl.fr/cas/login"; // CAS Login Endpoint
  HttpSession session = HttpSession(
      maxRedirects: 15,

  );
  DateTime? sessionDate;
  bool loadedFromDisk = false;
  Map<String,String> headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept-Encoding' : 'gzip, deflate, br'
};
  late Map<String,String> secureStorage;

  CASAuth(){
    _loadSecureStorage();
  }

  int _setSystemPassword(){
    return 1;
  }
  int _getSystemPassword(){
    if (Platform.isMacOS){
      print("We are on macOS");
    }
    else if (Platform.isLinux){
      print("We are on Linux");
    }
    return 1;
  }
  int _loadSecureStorage(){

      //File secureStorageFile = File(SECURE_STORAGE_PATH);
      //secureStorageFile.openRead();
      //Map<String,dynamic> res = jsonDecode(secureStorageFile.readAsStringSync());
      //secureStorage = res;
      return 1;
  }

  void _dumpSecureStorage() async{
    File secureStorageFile = File(SECURE_STORAGE_PATH);
    String strRes = jsonEncode(secureStorage);
    await secureStorageFile.writeAsString(strRes);
  }

  Future<int> loginToCas(login,password,service) async {
    DateTime startDate = DateTime.now();
    if (loadCASSession()){
      loadedFromDisk = true;
      sessionDate = DateTime.now();
      return 1;
    }
    if (!casServiceENUM.containsKey(service)){
      print("Service passed in parameters isn't supported or doesn't exists");
      return -1;
    }
    String casServiceEndpoint = casEndpoint + SERVICE_PARAM + casServiceENUM[service]!;
    Uri cseUri = Uri.parse(casServiceEndpoint); // cseURI stands for CasServiceEndpoitURI;
    Response loginPage = await session.get(
      cseUri,
      headers: headers
    );
    if (loginPage.statusCode != 200){
      print("Failed to recieve CAS Login page");
      return -1;
    }
    BeautifulSoup soup = BeautifulSoup(loginPage.body);
    Bs4Element? exec_field = soup.find('input', attrs: {"name": 'execution'});
    Bs4Element? event_id_field = soup.find('input', attrs: {"name": '_eventId'});
    if (exec_field == null || event_id_field == null){
      print("Failed finding required form field");
      return -1;
    }
    String execution = exec_field["value"]!;
    String eventID = event_id_field["value"]!;
    Map<String,dynamic> loginData = {
      'username':login,
      'password':password,
      'execution':execution,
      '_eventId': eventID,
      'submit' : 'SE CONNECTER'
    };
    Response response = await session.post(
      cseUri,
      headers: headers,
      body: loginData,
    );

    //prepareRequest();
    if (response.statusCode == 301 || response.statusCode == 303 || response.statusCode == 302){
      http.Response sd = await followRedirects(response);
      print("Redirected");
      if (sd.statusCode == 200){
        print("Conn sucessfull");
      }
    }
    else{
      print("Not redirected");
      //session.updateCookies(response);
    }
    print(session.cookieStore.cookies);
    saveCASSession();
    print("Delta between now and last conn request ${DateTime.now().difference(startDate).inSeconds} secondes");
    return 1;
  }

  /*Future<http.Response> _get(String url) async {
    final response = await client.get(
      Uri.parse(url),
      headers: {
        if (session.getCookies().isNotEmpty) 'Cookie': session.generateCookieHeader(),
      },
    );
    session.updateCookies(response);
    return response;
  }*/

  /*Future<http.StreamedResponse> getStreamed(String url) async {

    final request = http.Request('GET', Uri.parse(url))
      ..followRedirects = false
      ..headers['cookie'] = headers["Cookie"]!;
    http.StreamedResponse resp = await client.send(request);
    //session.updateCookiesFromStreamResponse(resp);
    prepareRequest();
    return resp;
  }*/

  // Seems to be necessary if there are specifics redirects to connect to the CAS service
  Future<http.Response> followRedirects(http.Response response) async {
    final url = response.headers["location"];
    /*final request = http.Request('GET', Uri.parse(url!))
      ..followRedirects = false
      ..headers['cookie'] = headers["Cookie"]!;
    http.StreamedResponse resp = await client.send(request);*/
    int redirectCount = 0;
    while ((response.statusCode == 302 || response.statusCode == 303) && redirectCount < 10) {
      final location = response.headers['location'];
      if (location == null) break;

      final newUrl = location.startsWith('http')
          ? location
          : Uri.parse(response.request!.url.toString()).resolve(location).toString();

      response = await session.get(Uri.parse(newUrl), headers: headers);
      redirectCount++;
      sleep(Duration(milliseconds: 20));
    }

    if (redirectCount >= 10) {
      throw Exception("Trop de redirections (boucle probable)");
    }
    if (response.statusCode == 200){
      print("ON A REUSSI A SE CONNECTER YAHOOOO");
    }

    return response;
  }

  /*prepareRequest(){
    headers["Cookie"] = session.generateCookieHeader();
  }*/

  bool loadCASSession(){

    return false;
  }

  bool saveCASSession(){
   return false;
  }
}