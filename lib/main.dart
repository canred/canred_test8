import 'dart:developer';

import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AAD OAuth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'AAD OAuth Home'),
      navigatorKey: navigatorKey,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final Config config = Config(
    tenant: 'd95c157f-48ac-41eb-957d-a457690f3bdc',
    clientId: '176d6ef5-e730-4f85-b6b6-a4b6ca2cbcea',
    //scope: 'openid profile offline_access',
    scope: 'openid profile offline_access',
    redirectUri: kIsWeb
        ? "your local host URL"
        : "msauth://com.example.canred_test8/MKp8RU%2Bky035Sf4NrBekkSC58X0%3D",
    navigatorKey: navigatorKey,
    //loader: SizedBox(),
    // appBar: AppBar(
    //   title: Text('AAD OAuth Demo'),
    // ),
    // onPageFinished: (String url) {
    //   log('onPageFinished: $url');
    // },
  );
  final AadOAuth oauth = AadOAuth(config);

  Future azureSignInApi(bool redirect) async {
    final AadOAuth oauth = AadOAuth(config);

    config.webUseRedirect = redirect;
    final result = await oauth.login();

    result.fold(
      (l) => showError("Microsoft Authentication Failed!"),
      (r) async {
        final result = await fetchAzureUserDetails(r.accessToken);
      },
    );
  }

  static Future fetchAzureUserDetails(accessToken) async {
    http.Response response;
    response = await http.get(
      Uri.parse("https://graph.microsoft.com/v1.0/me"),
      headers: {"Authorization": "Bearer $accessToken"},
    );

    print(json.decode(response.body));
    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(
              'AzureAD OAuth',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListTile(
            leading: Icon(Icons.launch),
            title: Text('Login${kIsWeb ? ' (web popup)' : ''}'),
            onTap: () {
              login(false);
            },
          ),
          if (kIsWeb)
            ListTile(
              leading: Icon(Icons.launch),
              title: Text('Login (web redirect)'),
              onTap: () {
                login(true);
              },
            ),
          ListTile(
            leading: Icon(Icons.data_array),
            title: Text('HasCachedAccountInformation'),
            onTap: () => hasCachedAccountInformation(),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              logout();
            },
          ),
        ],
      ),
    );
  }

  void showError(dynamic ex) {
    showMessage(ex.toString());
  }

  void showMessage(String text) {
    var alert = AlertDialog(content: Text(text), actions: <Widget>[
      TextButton(
          child: const Text('Ok'),
          onPressed: () {
            Navigator.pop(context);
          })
    ]);
    showDialog(context: context, builder: (BuildContext context) => alert);
  }

  void login(bool redirect) async {
    config.webUseRedirect = redirect;
    final result = await oauth.login();
    result.fold(
      (l) => showError(l.toString()),
      (r) async => await fetchAzureUserDetails(r.accessToken),
      //(r) async => showMessage("Microsoft Authentication Success!"),
    );
    var accessToken = await oauth.getAccessToken();
    if (accessToken != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(accessToken)));
    }
  }

  void hasCachedAccountInformation() async {
    var hasCachedAccountInformation = await oauth.hasCachedAccountInformation;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('HasCachedAccountInformation: $hasCachedAccountInformation'),
      ),
    );
  }

  void logout() async {
    await oauth.logout();
    showMessage('Logged out');
  }
}
