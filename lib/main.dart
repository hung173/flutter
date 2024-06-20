import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey webViewKey = GlobalKey();
  String url = '';
  bool isLoading = true;
  bool isFirst = true;
  bool isRefreshing = false;
  late InAppWebViewController mController;

  InAppWebViewSettings settings = InAppWebViewSettings(
      hardwareAcceleration: true,
      javaScriptEnabled: true,
      transparentBackground: true,
      alwaysBounceVertical: true,
      disallowOverScroll: true,
      isInspectable: kDebugMode);
  PullToRefreshController? pullToRefreshController;
  PullToRefreshSettings pullToRefreshSettings = PullToRefreshSettings(
    distanceToTriggerSync: 10,
    color: Colors.blue,
  );
  bool pullToRefreshEnabled = true;

  Future<void> fetchData() async {
    final response = await http
        .get(Uri.parse('http://appendo.phanmemdangky.com/config.json'));
    String _fcmToken = '';
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      _fcmToken = token;
    } else {
      print('Unable to get FCM token');
    }

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        // Assuming your JSON structure has a key named 'url'
        url = jsonData['appUrl'] + "?fcbkey=$_fcmToken";
        print("canhcanh $url");
      });
    } else {
      setState(() {
        url = '';
      });
      throw Exception('Failed to load data');
    }
  }

  void _checkInternetConnection() async {
    print("anhcanh");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
    } else {
      print("anhcanh1");
      if (url.isNotEmpty) {
        mController?.reload();
      } else {
        fetchData();
      }
    }
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> _initializeFirebase() async {
    // Request permission for receiving notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Configure Firebase messaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message: ${message.notification?.title}');
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
    _initializeFirebase();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      // Update connection status whenever it changes
      _checkInternetConnection();
    });
    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: pullToRefreshSettings,
            onRefresh: () async {
              print("canhcanh");
              if (defaultTargetPlatform == TargetPlatform.android) {
                mController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                mController?.loadUrl(
                    urlRequest: URLRequest(url: await mController?.getUrl()));
              }
            },
          );
  }

  Future<bool> _onBackPressed() async {
    if (await mController.canGoBack()) {
      mController.goBack();
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: url.isNotEmpty
            ? Stack(
                children: [
                  InAppWebView(
                    key: webViewKey,
                    initialUrlRequest: URLRequest(url: WebUri(url)),
                    initialSettings: settings,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (InAppWebViewController controller) {
                      mController = controller;
                    },
                    onLoadStop: (controller, url) {
                      setState(() {
                        isLoading = false;
                        isFirst = false;
                      });
                      pullToRefreshController?.endRefreshing();
                    },
                    onReceivedError: (controller, request, error) {
                      setState(() {
                        isLoading = false;
                      });
                      pullToRefreshController?.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController?.endRefreshing();
                      }
                    },
                    onLoadStart: (controller, progress) {
                      setState(() {
                        isLoading = true;
                      });
                    },
                  ),
                  isLoading && isFirst
                      ? Stack(
                          children: [
                            // Background image container
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                image: DecorationImage(
                                  image: AssetImage(
                                      'lib/assets/background_image.png'),
                                  fit: BoxFit.contain,
                                  alignment: FractionalOffset.center,
                                ),
                              ),
                            ),
                            // Other widgets on top of the background
                            Center(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Loading data...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            )),
                          ],
                        )
                      : Container(),
                ],
              )
            : Stack(
                children: [
                  // Background image container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image: DecorationImage(
                        image: AssetImage('lib/assets/background_image.png'),
                        fit: BoxFit.contain,
                        alignment: FractionalOffset.center,
                      ),
                    ),
                  ),
                  // Other widgets on top of the background
                  Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Loading data...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  )),
                ],
              ),
      ),
    );
  }
}

/*import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter_upload/webview_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String url = '';
  bool _isLoading = true;
  late final WebViewController controller;
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  Future<void> fetchData() async {
    final response = await http
        .get(Uri.parse('http://appendo.phanmemdangky.com/config.json'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        // Assuming your JSON structure has a key named 'url'
        url = jsonData['appUrl'];
      });
    } else {
      setState(() {
        url = '';
      });
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WebView.platform = SurfaceAndroidWebView();
    fetchData();
  }

  Future<void> _refresh() async {
    // Đợi 2 giây để mô phỏng việc làm mới dữ liệu
    print("canhcanh");
    if (url == '') {
      fetchData();
    } else {
      await Future.delayed(const Duration(seconds: 2));
      controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: RefreshIndicator(
      onRefresh: _refresh,
      child: url.isNotEmpty
          ? SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Stack(
                children: [
                  Container(
                    height: 1000,
                    child: WebView(
                      onWebResourceError: (error) => (
                        print("canhcanh $error")
                      ),
                      initialUrl: url,
                      javascriptMode: JavascriptMode.unrestricted,
                      onWebViewCreated: (WebViewController webViewController) {
                        //controller = webViewController;
                        _controller.complete(webViewController);
                      },
                      onPageFinished: (url) {
                        setState(() {
                          _isLoading = false;
                        });
                      },
                    ),
                  ),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ))
          : Stack(
              children: [
                // Background image container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                      image: AssetImage('lib/assets/background_image.png'),
                      fit: BoxFit.contain,
                      alignment: FractionalOffset.center,
                    ),
                  ),
                ),
                // Other widgets on top of the background
                Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    Text(
                      'Loading data...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                )),
              ],
            ),
    ));
  }
}*/

/*
WebView(
initialUrl: 'http://test.phanmemdangky.com/mobile/',
javascriptMode: JavascriptMode.unrestricted,
onWebViewCreated: (WebViewController webViewController) {
_controller.complete(webViewController);
},*/
/*
WebView(
initialUrl: url,
javascriptMode: JavascriptMode.unrestricted,
onWebViewCreated: (WebViewController webViewController) {
controller = webViewController;
_controller.complete(webViewController);
})*/

///////////////////////////////
/*
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

Future main() async {
*/
/*  WidgetsFlutterBinding.ensureInitialized();

  await Permission.camera.request();
  await Permission.microphone.request();*/ /*


  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: InAppWebViewPage());
  }
}

class InAppWebViewPage extends StatefulWidget {
  @override
  _InAppWebViewPageState createState() => new _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  late InAppWebViewController _webViewController;
  final GlobalKey webViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("InAppWebView")),
        body: Container(
            child: Column(children: <Widget>[
          Expanded(
            child: Container(
              height: 1000,
              child: InAppWebView(
                  key: webViewKey,
                  initialUrlRequest:
                      URLRequest(url: WebUri("http://test.phanmemdangky.com/mobile/")),
                  initialSettings: InAppWebViewSettings(
                      allowsBackForwardNavigationGestures: true),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  */
/*androidOnPermissionRequest:
                      (InAppWebViewController controller, String origin,
                          List<String> resources) async {
                    return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT);
                  }*/ /*
),
            ),
          ),
        ])));
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isLoading = true;
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InAppWebView with RefreshIndicator'),
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: _refreshIndicatorKey,
            initialUrlRequest: URLRequest(
                url: WebUri("http://test.phanmemdangky.com/mobile/")),
            initialSettings:
                InAppWebViewSettings(allowsBackForwardNavigationGestures: true),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            pullToRefreshController: PullToRefreshController(),
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
            },
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      // RefreshIndicator
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refreshIndicatorKey.currentState?.show();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
*/
