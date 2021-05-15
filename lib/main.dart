import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/twitch_user.dart';
import 'package:rtchat/screens/home.dart';
import 'package:rtchat/screens/settings.dart';
import 'package:rtchat/screens/sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const primarySwatch = MaterialColor(0xFF009FDF, {
  50: Color.fromRGBO(0, 159, 223, .1),
  100: Color.fromRGBO(0, 159, 223, .2),
  200: Color.fromRGBO(0, 159, 223, .3),
  300: Color.fromRGBO(0, 159, 223, .4),
  400: Color.fromRGBO(0, 159, 223, .5),
  500: Color.fromRGBO(0, 159, 223, .6),
  600: Color.fromRGBO(0, 159, 223, .7),
  700: Color.fromRGBO(0, 159, 223, .8),
  800: Color.fromRGBO(0, 159, 223, .9),
  900: Color.fromRGBO(0, 159, 223, 1),
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait(
            [Firebase.initializeApp(), SharedPreferences.getInstance()]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          final prefs = snapshot.data?[1];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(home: SignInScreen(loading: true));
          }

          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) {
                final model = TwitchUserModel.fromJson(
                    jsonDecode(prefs.getString("twitch_user") ?? "{}"));
                model.addListener(() {
                  prefs.setString("twitch_user", jsonEncode(model.toJson()));
                });
                return model;
              }),
              ChangeNotifierProvider(create: (context) {
                final model = LayoutModel.fromJson(
                    jsonDecode(prefs.getString("layout") ?? "{}"));
                model.addListener(() {
                  prefs.setString("layout", jsonEncode(model.toJson()));
                });
                return model;
              }),
              ChangeNotifierProvider(create: (context) => ChatHistoryModel()),
            ],
            child: MaterialApp(
              title: 'RealtimeChat',
              theme: ThemeData(
                fontFamily: 'Arial',
                brightness: Brightness.light,
                primarySwatch: primarySwatch,
              ),
              darkTheme: ThemeData(
                fontFamily: 'Arial',
                brightness: Brightness.dark,
                primarySwatch: primarySwatch,
                scaffoldBackgroundColor: Colors.black,
              ),
              initialRoute: '/',
              routes: {
                '/': (context) {
                  return Consumer<TwitchUserModel>(
                      builder: (context, model, child) {
                    if (!model.isSignedIn()) {
                      return SignInScreen(loading: false);
                    }
                    return HomeScreen();
                  });
                },
                '/settings': (context) => SettingsScreen(),
              },
            ),
          );
        });
  }
}
