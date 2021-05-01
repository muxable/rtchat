import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'dart:async';
import 'dart:io';

final clientId = 'edfnh2q85za8phifif9jxt3ey6t9b9';
final callbackUrlScheme = 'com.rtirl.chat';

final url = Uri.https('id.twitch.tv', '/oauth2/authorize', {
  'response_type': 'code',
  'client_id': clientId,
  'redirect_uri': '$callbackUrlScheme:/',
  'scope': ["chat:read", "chat:edit"],
}).toString();

class SettingsScreen extends StatefulWidget {
  SettingsScreen({Key key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void authenticate() async {
    try {
      stdout.writeln(url);
      final result = await FlutterWebAuth.authenticate(
          url: url, callbackUrlScheme: callbackUrlScheme);
      setState(() {});
    } catch (e) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MySettingsScreen object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Settings"),
      ),
      body: Column(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        children: [
          ElevatedButton(
            child: Text('You have pushed the button this many times:'),
            onPressed: () {
              this.authenticate();
            },
          ),
        ],
      ),
    );
  }
}
