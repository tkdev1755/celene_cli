import 'dart:io';
import 'dart:async';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:celene_cli/model/secureStorage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cookie_store/cookie_store.dart' as cStore;
import 'extensions.dart';
import 'package:http_session/http_session.dart';


Map<String, String> casServiceENUM = {
  "Celene" : "https%3A%2F%2Fcelene.insa-cvl.fr%2Flogin%2Findex.php"
};
/// {@category API-WEB}
/// Classe permettant la connexion au CAS de l'INSA CVL
class CASAuth{
  /// Paramètre service lorsqu'il faut se rediriger vers un service en particulier
  String SERVICE_PARAM = "?service=";
  /// Adresse du CAS de l'INSA CVL
  String casEndpoint = "https://cas.insa-cvl.fr/cas/login"; // CAS Login Endpoint

  /// Objet Sessions contenant les cookies et à partir duquel il faut effectuer les requêtes
  HttpSession session = HttpSession(
      maxRedirects: 15,
  );

  /// Date de création de la session
  DateTime? sessionDate;

  /// Indique si on est connecté correctement au CAS
  bool _sessionStatus = false;
  /// Headers pour simuler un vrai navigateur web
  Map<String,String> headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept-Encoding' : 'gzip, deflate, br'
  };

  /// Headers pour debug
  static String loadCasSessionDebugHeader = "[CASAuth - loadCasSession]";
  static String saveCasSessionDebugHeader = "[CASAuth - saveCasSession]";
  static String loginCasSessionDebugHeader = "[CASAuth - loginCas]";
  /// Objet SecureStorage permettant la persistance de session
  SecureStorage? secureStorage;

  CASAuth();

  /// Initialise le secureStorage si celui-ci exists
  setSecureStorage(SecureStorage sStorage){
    secureStorage = sStorage;
  }

  /// Fonction permettant de se connecter au CAS
  /// String login : Login de l'utilisatuer
  /// String password : Mot de passe de l'utilisateur
  /// String service : Service vers lequel effectuer la redirection
  Future<int> loginToCas(String login,String password, String service) async {
    DateTime startDate = DateTime.now();
    if (!casServiceENUM.containsKey(service)){
      logger("Service passed in parameters isn't supported or doesn't exists");
      return -1;
    }
    String casServiceEndpoint = casEndpoint + SERVICE_PARAM + casServiceENUM[service]!;
    Uri cseUri = Uri.parse(casServiceEndpoint); // cseURI stands for CasServiceEndpoitURI;
    Response loginPage = await session.get(
      cseUri,
      headers: headers
    );
    if (loginPage.statusCode != 200){
      logger("Failed to recieve CAS Login page");
      return -1;
    }
    BeautifulSoup soup = BeautifulSoup(loginPage.body);
    Bs4Element? exec_field = soup.find('input', attrs: {"name": 'execution'});
    Bs4Element? event_id_field = soup.find('input', attrs: {"name": '_eventId'});
    if (exec_field == null || event_id_field == null){
      logger("Failed finding required form field");
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
      logger("Redirected");
      if (sd.statusCode == 200){
        _sessionStatus = true;
        logger("Conn sucessfull");
      }
    }
    else{
      logger("Not redirected");
      return -1;
    }
    logger(session.cookieStore.cookies);
    logger("Delta between now and last conn request ${DateTime.now().difference(startDate).inSeconds} secondes");

    return 1;
  }


  // Seems to be necessary if there are specifics redirects to connect to the CAS service
  /// Fonction prenant en charge les redirections dans le cadre d'une connexion à un service
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
      logger("ON A REUSSI A SE CONNECTER YAHOOOO");
    }

    return response;
  }

  /// Fonction chargeant la session CAS si celle-ci existe
  /// prends les cookies à récupérer au sein du secureStorage
  /// Retourne vrai si session chargée correctement, faux sinon
  bool loadCASSession(List<(String,String,String)> keysToGet){
    String debugHeader = loadCasSessionDebugHeader;
    String errorMessage = "FALSE RETURN";
    if (secureStorage == null){
      logger("$debugHeader - $errorMessage : secure storage wasn't set");
      return false;
    }
    if (!secureStorage!.getSecureStorageStatus()){
      logger("$debugHeader - $errorMessage : secure storage exists but something hasn't loaded correctly");
      return false;
    }
    String? stringSessionDate = secureStorage!.getValue("sessionDate");
    if (stringSessionDate == null){
      logger("$debugHeader - $errorMessage : Session date value was non-existent in secure storage");
      return false;
    }
    else{
      DateTime sessionDate = DateFormat("dd/MM/yyyy-HH:mm").parse(stringSessionDate!);
      if (DateTime.now().difference(sessionDate).inMinutes > 30){
        logger("$debugHeader - $errorMessage : Session date was too old");
        return false;
      }
    }
    keysToGet.add(("casCookie","TGC","https://cas.insa-cvl.fr/"));
    for ((String,String,String) i in keysToGet){
      String? value = secureStorage!.getValue(i[0]);
      if (value == null){
        logger("$debugHeader - $errorMessage : searched cookie didn't exist in storage");
        return false;
      }
      cStore.Cookie newCookie = cStore.Cookie(
        i[1]!,
        value,
      );
      Uri websiteURI = Uri.parse(i[2]);
      newCookie.path = websiteURI.path;
      newCookie.domain = websiteURI.host;
      session.cookieStore.cookies.add(newCookie);
    }
    return true;
  }

  /// Fonction sauvegardant la session CAS dans le secureStorage
  /// Prends une liste de cookie à sauvegarder
  /// Retourne vrai si la session a été sauvegardée correctement
  Future<bool> saveCASSession(List<(String,String)> cookiesToSave) async {
    String debugHeader = saveCasSessionDebugHeader;
    String errorMessage = "FALSE RETURN";
    cookiesToSave.add(("TGC","casCookie"));
    if (sessionDate == null || secureStorage == null){
      logger("$debugHeader - $errorMessage : Either session date was null or the secure storage wasn't set");
      logger("Sessiondate ${sessionDate?.day} | secureStorage $secureStorage");
      return false;
    }
    if (!_sessionStatus){
      logger("$debugHeader - $errorMessage : Session wasn't initiated correctly");
      return false;
    }
    if (DateTime.now().difference(sessionDate!).inMinutes > 30){
      logger("$debugHeader - $errorMessage :  Session was too old ${DateTime.now().difference(sessionDate!).inMinutes}");
      return false;
    }
    if (!secureStorage!.getSecureStorageStatus()){
      logger("$debugHeader - $errorMessage : Secure storage wasn't set properly");
      logger("$debugHeader - $errorMessage : Here is all the data ${secureStorage!.getSecureStorageStatus()}");
      return false;
    }
    List<cStore.Cookie> cookiesJar = session.cookieStore.cookies;
    secureStorage!.setValue("sessionDate", DateFormat("dd/MM/yyyy-HH:mm").format(sessionDate!));
    for ((String,String) i in cookiesToSave){
      Iterable<cStore.Cookie> search =  cookiesJar.where((e) => e.name == i[0]);
      if (search.isEmpty){
        logger("$debugHeader - $errorMessage : Value researched wasn't found in the cookie");
        return false;
      }
      secureStorage!.setValue(i[1], search.first.value);
    }

    bool dumpResult = await secureStorage!.dump();
    return dumpResult;
  }
}