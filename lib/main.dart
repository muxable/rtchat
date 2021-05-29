import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/twitch/badge.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/home.dart';
import 'package:rtchat/screens/settings.dart';
import 'package:rtchat/screens/sign_in.dart';
import 'package:rtchat/screens/twitch/badges.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  if (kDebugMode) {
    runApp(App(prefs: prefs));
  } else {
    runZonedGuarded(() {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      runApp(App(prefs: prefs));
    }, FirebaseCrashlytics.instance.recordError);
  }
}

class App extends StatelessWidget {
  final SharedPreferences prefs;

  App({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserModel()),
        ChangeNotifierProvider(create: (context) {
          final model = LayoutModel.fromJson(
              jsonDecode(prefs.getString("layout") ?? "{}"));
          model.addListener(() {
            prefs.setString("layout", jsonEncode(model.toJson()));
          });
          return model;
        }),
        ChangeNotifierProxyProvider<UserModel, ChatHistoryModel>(
            create: (context) => ChatHistoryModel(TtsModel()),
            update: (context, user, chatHistory) => (chatHistory == null
                ? ChatHistoryModel(TtsModel())
                : chatHistory)
              ..subscribe(user.channels)),
        ChangeNotifierProxyProvider<UserModel, TwitchBadgeModel>(
            create: (context) => TwitchBadgeModel(),
            update: (context, user, twitchBadge) =>
                (twitchBadge == null ? TwitchBadgeModel() : twitchBadge)
                  ..bind(user.channels)),
      ],
      child: MaterialApp(
        title: 'RealtimeChat',
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: primarySwatch,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: primarySwatch,
          scaffoldBackgroundColor: Colors.black,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) {
            return Consumer<UserModel>(builder: (context, model, child) {
              if (!model.isSignedIn()) {
                return SignInScreen();
              }
              return HomeScreen();
            });
          },
          '/settings': (context) => SettingsScreen(),
          '/settings/badges': (context) => TwitchBadgesScreen(),
        },
      ),
    );
  }
}
