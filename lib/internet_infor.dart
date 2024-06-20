/*

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';

class InternetConnectionWidget extends StatefulWidget {
  @override
  _InternetConnectionWidgetState createState() =>
      _InternetConnectionWidgetState();
}


class _InternetConnectionWidgetState extends State<InternetConnectionWidget> {
  late ConnectivityResult _connectionStatus;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectionStatus = result;
      });
    });
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _connectionStatus = connectivityResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    String connectionStatusMsg = 'Internet connection: ';
    if (_connectionStatus == ConnectivityResult.mobile) {
      connectionStatusMsg += 'Mobile data';
    } else if (_connectionStatus == ConnectivityResult.wifi) {
      connectionStatusMsg += 'WiFi';
    } else {
      connectionStatusMsg += 'No connection';
    }

    return Text(connectionStatusMsg);
  }
}*/
